from aiogram import Bot, Dispatcher, types
from aiogram.contrib.fsm_storage.memory import MemoryStorage
from aiogram.dispatcher import FSMContext
from aiogram.dispatcher.filters.state import State, StatesGroup
from aiogram.types import InlineKeyboardMarkup, InlineKeyboardButton, CallbackQuery, LabeledPrice, PreCheckoutQuery
import asyncio
import os
from datetime import datetime, timedelta
from supabase import create_client, Client
from dotenv import load_dotenv
import json
from payments import ClickUzPayment
from zoom import ZoomMeeting
from bitrix24 import Bitrix24Calendar

# Load environment variables
load_dotenv()

# Initialize bot and dispatcher
bot = Bot(token=os.getenv('TELEGRAM_BOT_TOKEN'))
storage = MemoryStorage()
dp = Dispatcher(bot, storage=storage)

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_ANON_KEY')
)

# Initialize Click.uz payment
click_payment = ClickUzPayment()
# Enable test mode during development
click_payment.set_test_mode(True)  # Set to False in production

# Initialize Zoom client
zoom = ZoomMeeting(
    account_id=os.getenv('ZOOM_ACCOUNT_ID'),
    client_id=os.getenv('ZOOM_CLIENT_ID'),
    client_secret=os.getenv('ZOOM_CLIENT_SECRET')
)

# Initialize Bitrix24 client
bitrix24 = Bitrix24Calendar(os.getenv('BITRIX24_WEBHOOK_URL'))

# States
class BookingStates(StatesGroup):
    selecting_language = State()
    selecting_staff = State()
    selecting_date = State()
    selecting_time = State()
    confirming = State()
    processing_payment = State()

# Language selection keyboard
language_keyboard = InlineKeyboardMarkup(row_width=1)
language_keyboard.add(
    InlineKeyboardButton("🇺🇸 English", callback_data="lang_en"),
    InlineKeyboardButton("🇷🇺 Русский", callback_data="lang_ru"),
    InlineKeyboardButton("🇺🇿 O'zbek", callback_data="lang_uz")
)

# Translations
translations = {
    'en': {
        'welcome': "Welcome to our booking system! Please select your language.",
        'select_staff': "Please select a staff member:",
        'select_date': "Please select a date:",
        'select_time': "Please select a time slot:",
        'confirm': "Please confirm your booking:",
        'confirmed': "Your booking has been confirmed! You will receive a Zoom link shortly.",
        'cancelled': "Booking cancelled.",
        'payment': "Please complete the payment to confirm your booking.",
        'payment_success': "Payment successful! Your booking is confirmed.",
        'payment_error': "Payment failed. Please try again or contact support."
    },
    'ru': {
        'welcome': "Добро пожаловать в нашу систему бронирования! Пожалуйста, выберите язык.",
        'select_staff': "Пожалуйста, выберите специалиста:",
        'select_date': "Пожалуйста, выберите дату:",
        'select_time': "Пожалуйста, выберите время:",
        'confirm': "Пожалуйста, подтвердите бронирование:",
        'confirmed': "Ваше бронирование подтверждено! Вы получите ссылку Zoom в ближайшее время.",
        'cancelled': "Бронирование отменено.",
        'payment': "Пожалуйста, выполните оплату для подтверждения бронирования.",
        'payment_success': "Оплата прошла успешно! Ваше бронирование подтверждено.",
        'payment_error': "Ошибка оплаты. Пожалуйста, попробуйте снова или обратитесь в поддержку."
    },
    'uz': {
        'welcome': "Bizning bron qilish tizimimizga xush kelibsiz! Iltimos, tilni tanlang.",
        'select_staff': "Iltimos, xodimni tanlang:",
        'select_date': "Iltimos, sanani tanlang:",
        'select_time': "Iltimos, vaqtni tanlang:",
        'confirm': "Iltimos, bronni tasdiqlang:",
        'confirmed': "Sizning broningiz tasdiqlandi! Tez orada Zoom havolasini olasiz.",
        'cancelled': "Bron bekor qilindi.",
        'payment': "Bronni tasdiqlash uchun to'lovni amalga oshiring.",
        'payment_success': "To'lov muvaffaqiyatli amalga oshirildi! Sizning broningiz tasdiqlandi.",
        'payment_error': "To'lov amalga oshmadi. Iltimos, qayta urinib ko'ring yoki yordam xizmatiga murojaat qiling."
    }
}

@dp.message_handler(commands=['start'])
async def cmd_start(message: types.Message):
    await BookingStates.selecting_language.set()
    await message.answer("🌍 Welcome! Please select your language:", reply_markup=language_keyboard)

@dp.callback_query_handler(lambda c: c.data.startswith('lang_'), state=BookingStates.selecting_language)
async def process_language_selection(callback_query: CallbackQuery, state: FSMContext):
    language = callback_query.data.split('_')[1]
    
    # Store user data in Supabase
    user_data = {
        'telegram_id': str(callback_query.from_user.id),
        'name': callback_query.from_user.full_name,
        'language': language
    }
    
    try:
        supabase.table('users').upsert(user_data).execute()
    except Exception as e:
        print(f"Error storing user data: {e}")
    
    await state.update_data(language=language)
    
    # Fetch available staff
    staff_data = supabase.table('staff').select('*').eq('available', True).execute()
    staff_list = staff_data.data
    
    # Create staff selection keyboard
    staff_keyboard = InlineKeyboardMarkup(row_width=1)
    for staff in staff_list:
        staff_keyboard.add(InlineKeyboardButton(
            staff['name'],
            callback_data=f"staff_{staff['id']}"
        ))
    
    await BookingStates.selecting_staff.set()
    await callback_query.message.edit_text(
        translations[language]['select_staff'],
        reply_markup=staff_keyboard
    )

@dp.callback_query_handler(lambda c: c.data.startswith('staff_'), state=BookingStates.selecting_staff)
async def process_staff_selection(callback_query: CallbackQuery, state: FSMContext):
    staff_id = callback_query.data.split('_')[1]
    user_data = await state.get_data()
    language = user_data.get('language', 'en')
    
    await state.update_data(staff_id=staff_id)
    
    # Get available dates for the selected staff
    today = datetime.now().date()
    dates = []
    for i in range(14):  # Show next 14 days
        date = today + timedelta(days=i)
        schedule = supabase.table('schedules').select('*').eq('staff_id', staff_id).eq('date', date.isoformat()).execute()
        if schedule.data and schedule.data[0]['is_working']:
            dates.append(date)
    
    # Create date selection keyboard
    date_keyboard = InlineKeyboardMarkup(row_width=3)
    for date in dates:
        date_keyboard.insert(InlineKeyboardButton(
            date.strftime("%d/%m"),
            callback_data=f"date_{date.isoformat()}"
        ))
    
    await BookingStates.selecting_date.set()
    await callback_query.message.edit_text(
        translations[language]['select_date'],
        reply_markup=date_keyboard
    )

@dp.callback_query_handler(lambda c: c.data.startswith('date_'), state=BookingStates.selecting_date)
async def process_date_selection(callback_query: CallbackQuery, state: FSMContext):
    date = callback_query.data.split('_')[1]
    user_data = await state.get_data()
    language = user_data.get('language', 'en')
    staff_id = user_data.get('staff_id')
    
    await state.update_data(date=date)
    
    # Get available time slots
    schedule = supabase.table('schedules').select('id').eq('staff_id', staff_id).eq('date', date).single().execute()
    if schedule.data:
        time_slots = supabase.table('time_slots').select('*').eq('schedule_id', schedule.data['id']).execute()
        
        # Create time selection keyboard
        time_keyboard = InlineKeyboardMarkup(row_width=2)
        for slot in time_slots.data:
            time_keyboard.insert(InlineKeyboardButton(
                f"{slot['start_time']} - {slot['end_time']}",
                callback_data=f"time_{slot['start_time']}_{slot['end_time']}"
            ))
        
        await BookingStates.selecting_time.set()
        await callback_query.message.edit_text(
            translations[language]['select_time'],
            reply_markup=time_keyboard
        )
    else:
        await callback_query.message.edit_text("No available time slots for this date.")

@dp.callback_query_handler(lambda c: c.data.startswith('time_'), state=BookingStates.selecting_time)
async def process_time_selection(callback_query: CallbackQuery, state: FSMContext):
    start_time, end_time = callback_query.data.split('_')[1:]
    user_data = await state.get_data()
    language = user_data.get('language', 'en')
    staff_id = user_data.get('staff_id')
    date = user_data.get('date')
    
    # Create booking in database
    booking_data = {
        'user_id': callback_query.from_user.id,
        'staff_id': staff_id,
        'date': date,
        'start_time': start_time,
        'end_time': end_time,
        'status': 'pending'
    }
    
    booking = supabase.table('bookings').insert(booking_data).execute()
    
    if booking.data:
        booking_id = booking.data[0]['id']
        await state.update_data(booking_id=booking_id)
        
        # Create confirmation keyboard
        confirm_keyboard = InlineKeyboardMarkup(row_width=2)
        confirm_keyboard.add(
            InlineKeyboardButton("✅ Confirm", callback_data=f"confirm_booking_{booking_id}"),
            InlineKeyboardButton("❌ Cancel", callback_data=f"cancel_booking_{booking_id}")
        )
        
        staff = supabase.table('staff').select('*').eq('id', staff_id).single().execute()
        
        confirmation_text = f"""
Please confirm your booking:

Staff: {staff.data['name']}
Date: {date}
Time: {start_time} - {end_time}
Price: {staff.data['pricing']} UZS
"""
        
        await BookingStates.confirming.set()
        await callback_query.message.edit_text(
            confirmation_text,
            reply_markup=confirm_keyboard
        )
    else:
        await callback_query.message.edit_text("Error creating booking. Please try again.")

@dp.callback_query_handler(lambda c: c.data.startswith('confirm_booking_'), state=BookingStates.confirming)
async def process_booking_confirmation(callback_query: CallbackQuery, state: FSMContext):
    booking_id = callback_query.data.split('_')[2]
    user_data = await state.get_data()
    language = user_data.get('language', 'en')
    
    # Get booking details from Supabase
    booking = supabase.table('bookings').select(
        'bookings.id',
        'bookings.date',
        'bookings.start_time',
        'bookings.end_time',
        'bookings.status',
        'staff(name, pricing)'
    ).eq('id', booking_id).single().execute()
    
    if not booking.data:
        await callback_query.message.edit_text("Booking not found.")
        return
    
    # Create payment invoice
    title = f"Booking with {booking.data['staff']['name']}"
    description = f"Date: {booking.data['date']}\nTime: {booking.data['start_time']}-{booking.data['end_time']}"
    amount = booking.data['staff']['pricing']
    
    invoice_data = await click_payment.create_invoice(
        chat_id=callback_query.from_user.id,
        title=title,
        description=description,
        amount=amount,
        payload=booking_id
    )
    
    if invoice_data:
        await bot.send_invoice(**invoice_data)
        await callback_query.message.edit_text(translations[language]['payment'])
        await BookingStates.processing_payment.set()
    else:
        await callback_query.message.edit_text("Error creating payment. Please try again.")

@dp.callback_query_handler(lambda c: c.data.startswith('cancel_booking_'), state=BookingStates.confirming)
async def process_booking_cancellation(callback_query: CallbackQuery, state: FSMContext):
    booking_id = callback_query.data.split('_')[2]
    user_data = await state.get_data()
    language = user_data.get('language', 'en')
    
    # Update booking status to cancelled
    supabase.table('bookings').update({
        'status': 'cancelled'
    }).eq('id', booking_id).execute()
    
    await callback_query.message.edit_text(translations[language]['cancelled'])
    await state.finish()

@dp.pre_checkout_query_handler(state=BookingStates.processing_payment)
async def process_pre_checkout_query(pre_checkout_query: PreCheckoutQuery, state: FSMContext):
    """Handle the pre-checkout query"""
    try:
        # Verify the payment
        if await click_payment.verify_payment(pre_checkout_query):
            await bot.answer_pre_checkout_query(pre_checkout_query.id, ok=True)
        else:
            await bot.answer_pre_checkout_query(
                pre_checkout_query.id,
                ok=False,
                error_message="Payment verification failed. Please try again."
            )
    except Exception as e:
        print(f"Error in pre-checkout: {e}")
        await bot.answer_pre_checkout_query(
            pre_checkout_query.id,
            ok=False,
            error_message="An error occurred. Please try again."
        )

@dp.message_handler(content_types=types.ContentType.SUCCESSFUL_PAYMENT, state=BookingStates.processing_payment)
async def process_successful_payment(message: types.Message, state: FSMContext):
    """Handle successful payment"""
    try:
        user_data = await state.get_data()
        language = user_data.get('language', 'en')
        booking_id = message.successful_payment.invoice_payload
        
        # Update booking status in database
        supabase.table('bookings').update({
            'status': 'confirmed',
            'payment_id': message.successful_payment.provider_payment_charge_id
        }).eq('id', booking_id).execute()
        
        # Get booking details
        booking = supabase.table('bookings').select(
            'date', 'start_time', 'end_time', 'staff(name)'
        ).eq('id', booking_id).single().execute()
        
        if booking.data:
            start_datetime = datetime.strptime(
                f"{booking.data['date']} {booking.data['start_time']}", 
                "%Y-%m-%d %H:%M:%S"
            )
            end_datetime = datetime.strptime(
                f"{booking.data['date']} {booking.data['end_time']}", 
                "%Y-%m-%d %H:%M:%S"
            )
            duration = (end_datetime - start_datetime).seconds // 60
            
            # Create Zoom meeting
            meeting = await zoom.create_meeting(
                topic=f"Session with {booking.data['staff']['name']}",
                start_time=start_datetime,
                duration=duration
            )
            
            # Create Bitrix24 calendar event
            event_id = await bitrix24.create_event(
                title=f"Session with {message.from_user.full_name}",
                description=f"Zoom meeting: {meeting['join_url'] if meeting else 'Link will be provided'}\n\n"
                           f"Client: {message.from_user.full_name}\n"
                           f"Staff: {booking.data['staff']['name']}",
                start_date=start_datetime,
                end_date=end_datetime,
                attendees=[message.from_user.username] if message.from_user.username else []
            )
            
            # Update booking with Zoom and Bitrix24 info
            update_data = {}
            if meeting:
                update_data['zoom_link'] = meeting['join_url']
            if event_id:
                update_data['bitrix_event_id'] = event_id
            
            if update_data:
                supabase.table('bookings').update(update_data).eq('id', booking_id).execute()
            
            # Send confirmation to user
            confirmation_message = f"{translations[language]['payment_success']}\n\n"
            if meeting:
                confirmation_message += f"Zoom meeting link: {meeting['join_url']}\n"
            
            await message.answer(confirmation_message)
        
        await state.finish()
    except Exception as e:
        print(f"Error processing successful payment: {e}")
        await message.answer(translations[language]['payment_error'])
        await state.finish()

async def main():
    # Start polling
    await dp.start_polling()

if __name__ == '__main__':
    asyncio.run(main())
import os
from typing import Optional, Dict, Any
from datetime import datetime
import json
from supabase import create_client, Client

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_ANON_KEY')
)

class Database:
    @staticmethod
    async def manage_user(
        telegram_id: str,
        name: str,
        phone: Optional[str],
        language: str = 'en'
    ) -> str:
        """Create or update user in database"""
        try:
            result = await supabase.rpc(
                'bot_manage_user',
                {
                    'p_telegram_id': str(telegram_id),
                    'p_name': name,
                    'p_phone': phone,
                    'p_language': language
                }
            ).execute()
            return result.data
        except Exception as e:
            print(f"Error managing user: {e}")
            raise

    @staticmethod
    async def create_booking(
        telegram_id: str,
        staff_id: str,
        date: datetime,
        start_time: str,
        end_time: str
    ) -> Dict[str, Any]:
        """Create a new booking"""
        try:
            result = await supabase.rpc(
                'bot_create_booking',
                {
                    'p_telegram_id': str(telegram_id),
                    'p_staff_id': staff_id,
                    'p_date': date.strftime('%Y-%m-%d'),
                    'p_start_time': start_time,
                    'p_end_time': end_time
                }
            ).execute()
            
            if not result.data['success']:
                raise Exception(result.data['error'])
                
            return result.data
        except Exception as e:
            print(f"Error creating booking: {e}")
            raise

    @staticmethod
    async def get_staff_schedule(staff_id: str, date: datetime) -> list:
        """Get available time slots for staff member"""
        try:
            result = await supabase.rpc(
                'bot_get_staff_schedule',
                {
                    'p_staff_id': staff_id,
                    'p_date': date.strftime('%Y-%m-%d')
                }
            ).execute()
            return result.data
        except Exception as e:
            print(f"Error getting staff schedule: {e}")
            raise

    @staticmethod
    async def update_booking_status(
        booking_id: str,
        status: str,
        payment_id: Optional[str] = None,
        zoom_link: Optional[str] = None,
        bitrix_event_id: Optional[str] = None
    ) -> bool:
        """Update booking status and related information"""
        try:
            result = await supabase.rpc(
                'bot_update_booking_status',
                {
                    'p_booking_id': booking_id,
                    'p_status': status,
                    'p_payment_id': payment_id,
                    'p_zoom_link': zoom_link,
                    'p_bitrix_event_id': bitrix_event_id
                }
            ).execute()
            return result.data
        except Exception as e:
            print(f"Error updating booking status: {e}")
            raise
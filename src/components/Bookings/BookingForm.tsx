import React, { useState, useEffect } from 'react';
import { Booking, StaffMember } from '../../types';
import { X, Loader2, AlertCircle } from 'lucide-react';
import { staffAPI } from '../../lib/staff-api';
import { bookingAPI } from '../../lib/booking-api';
import { supabase } from '../../lib/supabase';
import { useInterval } from '../../hooks/useInterval';

type BookingFormProps = {
  booking?: Booking;
  onSubmit: (data: Partial<Booking>) => Promise<void>;
  onCancel: () => void;
};

type TimeSlot = {
  start_time: string;
  end_time: string;
  is_available: boolean;
};

const BookingForm: React.FC<BookingFormProps> = ({
  booking,
  onSubmit,
  onCancel
}) => {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [selectedStaffId, setSelectedStaffId] = useState(booking?.staff_id || '');
  const [selectedDate, setSelectedDate] = useState(booking?.date || '');
  const [availableSlots, setAvailableSlots] = useState<TimeSlot[]>([]);
  const [selectedSlot, setSelectedSlot] = useState<TimeSlot | null>(
    booking ? { 
      start_time: booking.start_time, 
      end_time: booking.end_time,
      is_available: true 
    } : null
  );
  const [userData, setUserData] = useState({
    name: booking?.users?.name || '',
    phone: booking?.users?.phone || ''
  });
  const [isLoading, setIsLoading] = useState(false);
  const [isCheckingAvailability, setIsCheckingAvailability] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (selectedStaffId && selectedDate) {
      const subscription = supabase
        .channel('booking-changes')
        .on(
          'postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'bookings',
            filter: `staff_id=eq.${selectedStaffId} AND date=eq.${selectedDate}`
          },
          () => {
            loadAvailableSlots();
          }
        )
        .subscribe();

      return () => {
        subscription.unsubscribe();
      };
    }
  }, [selectedStaffId, selectedDate]);

  useInterval(() => {
    if (selectedStaffId && selectedDate) {
      loadAvailableSlots();
    }
  }, 30000);

  useEffect(() => {
    loadStaff();
  }, []);

  useEffect(() => {
    if (selectedStaffId && selectedDate) {
      loadAvailableSlots();
    }
  }, [selectedStaffId, selectedDate]);

  const loadStaff = async () => {
    try {
      const data = await staffAPI.getStaff();
      setStaff(data.filter(s => s.available));
    } catch (err) {
      setError('Failed to load staff members');
      console.error(err);
    }
  };

  const loadAvailableSlots = async () => {
    try {
      setIsCheckingAvailability(true);
      const slots = await bookingAPI.getAvailableTimeSlots(selectedStaffId, selectedDate);
      setAvailableSlots(slots);
      
      if (selectedSlot && !slots.some(
        slot => slot.start_time === selectedSlot.start_time && 
               slot.end_time === selectedSlot.end_time &&
               slot.is_available
      )) {
        setSelectedSlot(null);
        setError('Previously selected time slot is no longer available');
      }
    } catch (err) {
      setError('Failed to load available time slots');
      console.error(err);
    } finally {
      setIsCheckingAvailability(false);
    }
  };

  const validateTimeSlot = async () => {
    if (!selectedStaffId || !selectedDate || !selectedSlot) {
      return false;
    }

    try {
      const isAvailable = await bookingAPI.checkAvailability({
        staff_id: selectedStaffId,
        date: selectedDate,
        start_time: selectedSlot.start_time,
        end_time: selectedSlot.end_time,
        booking_id: booking?.id
      });

      if (!isAvailable) {
        setError('Selected time slot is no longer available');
        loadAvailableSlots();
        return false;
      }

      return true;
    } catch (err) {
      setError('Failed to validate time slot availability');
      console.error(err);
      return false;
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStaffId || !selectedDate || !selectedSlot) {
      setError('Please fill in all required fields');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      // Validate time slot availability before proceeding
      const isSlotAvailable = await validateTimeSlot();
      if (!isSlotAvailable) {
        setIsLoading(false);
        return;
      }

      // Create a new user record for this booking
      const { data: newUser, error: insertError } = await supabase
        .from('users')
        .insert({
          telegram_id: `temp_${Date.now()}`, // Temporary ID for demo
          name: userData.name,
          phone: userData.phone,
          language: 'en'
        })
        .select('id')
        .single();

      if (insertError) throw insertError;

      const bookingData = {
        user_id: newUser.id,
        staff_id: selectedStaffId,
        date: selectedDate,
        start_time: selectedSlot.start_time,
        end_time: selectedSlot.end_time,
        status: booking?.status || 'pending'
      };

      if (booking) {
        await bookingAPI.updateBooking(booking.id, bookingData);
      } else {
        await bookingAPI.createBooking(bookingData);
      }

      await onSubmit(bookingData);
      onCancel();
    } catch (err: any) {
      // Handle specific error cases
      if (err.message?.includes('check_booking_availability') || 
          err.message?.includes('Time slot conflicts with existing booking')) {
        setError('This time slot is no longer available - another booking was just made');
        await loadAvailableSlots(); // Refresh available slots
        setSelectedSlot(null); // Clear the selected slot
      } else if (err.code === '23505' && err.message?.includes('users_telegram_id_key')) {
        setError('A user with this information already exists');
      } else {
        setError(err.message || 'Failed to save booking');
      }
      console.error('Booking error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full flex items-center justify-center">
      <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        <div className="flex justify-between items-center p-6 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">
            {booking ? 'Edit Booking' : 'New Booking'}
          </h3>
          <button
            onClick={onCancel}
            className="text-gray-400 hover:text-gray-500"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6">
          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative flex items-center">
              <AlertCircle size={16} className="mr-2 flex-shrink-0" />
              {error}
            </div>
          )}

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Staff Member
              </label>
              <select
                value={selectedStaffId}
                onChange={(e) => setSelectedStaffId(e.target.value)}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              >
                <option value="">Select staff member</option>
                {staff.map((member) => (
                  <option key={member.id} value={member.id}>
                    {member.name} - {member.position}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Date
              </label>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                min={new Date().toISOString().split('T')[0]}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                required
              />
            </div>

            {selectedStaffId && selectedDate && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Time Slot
                </label>
                {isCheckingAvailability ? (
                  <div className="flex items-center justify-center py-4">
                    <Loader2 size={24} className="animate-spin text-blue-600" />
                  </div>
                ) : (
                  <div className="grid grid-cols-2 gap-2">
                    {availableSlots.length > 0 ? (
                      availableSlots.map((slot, index) => (
                        <button
                          key={index}
                          type="button"
                          onClick={() => setSelectedSlot(slot)}
                          disabled={!slot.is_available}
                          className={`px-3 py-2 text-sm rounded-lg border ${
                            selectedSlot?.start_time === slot.start_time
                              ? 'border-blue-600 bg-blue-50 text-blue-700'
                              : slot.is_available
                              ? 'border-gray-300 hover:bg-gray-50'
                              : 'border-gray-200 bg-gray-100 text-gray-400 cursor-not-allowed'
                          }`}
                        >
                          {slot.start_time} - {slot.end_time}
                          {!slot.is_available && (
                            <span className="block text-xs text-gray-500">
                              Booked
                            </span>
                          )}
                        </button>
                      ))
                    ) : (
                      <div className="col-span-2 text-sm text-gray-500 text-center py-2">
                        No available time slots for this date
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Client Name
              </label>
              <input
                type="text"
                value={userData.name}
                onChange={(e) => setUserData({ ...userData, name: e.target.value })}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter client name"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Phone Number
              </label>
              <input
                type="tel"
                value={userData.phone}
                onChange={(e) => setUserData({ ...userData, phone: e.target.value })}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="+998 90 123 45 67"
              />
            </div>
          </div>

          <div className="mt-6 flex justify-end space-x-3">
            <button
              type="button"
              onClick={onCancel}
              className="px-4 py-2 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading || !selectedSlot}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
            >
              {isLoading ? (
                <>
                  <Loader2 size={16} className="animate-spin mr-2" />
                  Saving...
                </>
              ) : (
                booking ? 'Update Booking' : 'Create Booking'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BookingForm;
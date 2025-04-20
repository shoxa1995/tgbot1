import React, { useState, useEffect } from 'react';
import MainLayout from '../components/Layout/MainLayout';
import BookingsList from '../components/Bookings/BookingsList';
import BookingForm from '../components/Bookings/BookingForm';
import { Booking } from '../types';
import { bookingAPI } from '../lib/booking-api';

const BookingsPage: React.FC = () => {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalBookings, setTotalBookings] = useState(0);
  const [isFormVisible, setIsFormVisible] = useState(false);
  const [editingBooking, setEditingBooking] = useState<Booking | null>(null);
  const bookingsPerPage = 10;

  useEffect(() => {
    loadBookings();
  }, [currentPage]);

  const loadBookings = async () => {
    try {
      setIsLoading(true);
      const data = await bookingAPI.getBookings();
      setBookings(data);
      setTotalBookings(data.length);
      setError(null);
    } catch (err) {
      console.error('Error loading bookings:', err);
      setError('Failed to load bookings');
    } finally {
      setIsLoading(false);
    }
  };

  const handleDeleteBooking = async (id: string) => {
    if (confirm('Are you sure you want to delete this booking? This action cannot be undone.')) {
      try {
        await bookingAPI.deleteBooking(id);
        setBookings(bookings.filter(booking => booking.id !== id));
      } catch (err) {
        console.error('Error deleting booking:', err);
        setError('Failed to delete booking');
      }
    }
  };

  const handleUpdateStatus = async (id: string, status: Booking['status']) => {
    try {
      const updatedBooking = await bookingAPI.updateBooking(id, { status });
      setBookings(bookings.map(booking => 
        booking.id === id ? updatedBooking : booking
      ));
    } catch (err) {
      console.error('Error updating booking status:', err);
      setError('Failed to update booking status');
    }
  };

  const handleSearch = (query: string) => {
    setSearchQuery(query);
    setCurrentPage(1);
  };

  const handleAddBooking = () => {
    setEditingBooking(null);
    setIsFormVisible(true);
  };

  const handleEditBooking = (booking: Booking) => {
    setEditingBooking(booking);
    setIsFormVisible(true);
  };

  const handleFormSubmit = async (data: Partial<Booking>) => {
    try {
      if (editingBooking) {
        const updated = await bookingAPI.updateBooking(editingBooking.id, data);
        setBookings(bookings.map(b => b.id === editingBooking.id ? updated : b));
      } else {
        const created = await bookingAPI.createBooking(data as Omit<Booking, 'id' | 'created_at' | 'updated_at'>);
        setBookings([created, ...bookings]);
      }
      setIsFormVisible(false);
      setEditingBooking(null);
    } catch (err) {
      console.error('Error saving booking:', err);
      throw err;
    }
  };

  const filteredBookings = bookings.filter(booking => {
    const searchStr = searchQuery.toLowerCase();
    return (
      booking.users?.name.toLowerCase().includes(searchStr) ||
      booking.staff?.name.toLowerCase().includes(searchStr) ||
      booking.date.includes(searchStr) ||
      booking.status.toLowerCase().includes(searchStr)
    );
  });

  const paginatedBookings = filteredBookings.slice(
    (currentPage - 1) * bookingsPerPage,
    currentPage * bookingsPerPage
  );

  const totalPages = Math.ceil(filteredBookings.length / bookingsPerPage);

  if (isLoading) {
    return (
      <MainLayout title="Bookings">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout title="Bookings">
      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative">
          {error}
        </div>
      )}
      
      <BookingsList
        bookings={paginatedBookings}
        onDelete={handleDeleteBooking}
        onUpdateStatus={handleUpdateStatus}
        onSearch={handleSearch}
        searchQuery={searchQuery}
        currentPage={currentPage}
        totalPages={totalPages}
        onPageChange={setCurrentPage}
        totalBookings={totalBookings}
        onAdd={handleAddBooking}
        onEdit={handleEditBooking}
      />

      {isFormVisible && (
        <BookingForm
          booking={editingBooking || undefined}
          onSubmit={handleFormSubmit}
          onCancel={() => {
            setIsFormVisible(false);
            setEditingBooking(null);
          }}
        />
      )}
    </MainLayout>
  );
};

export default BookingsPage;
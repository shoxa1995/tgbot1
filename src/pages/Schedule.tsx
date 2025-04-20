import React, { useState, useEffect } from 'react';
import MainLayout from '../components/Layout/MainLayout';
import ScheduleCalendar from '../components/Schedule/ScheduleCalendar';
import { staffAPI } from '../lib/staff-api';
import { scheduleAPI } from '../lib/schedule-api';
import { DaySchedule, TimeSlot, StaffMember } from '../types';

const SchedulePage: React.FC = () => {
  const [selectedStaffId, setSelectedStaffId] = useState<string>('');
  const [currentWeekIndex, setCurrentWeekIndex] = useState(0);
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [weekSchedule, setWeekSchedule] = useState<DaySchedule[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    loadStaff();
  }, []);

  useEffect(() => {
    if (selectedStaffId) {
      loadSchedule();
    }
  }, [selectedStaffId, currentWeekIndex]);

  const loadStaff = async () => {
    try {
      const data = await staffAPI.getStaff();
      if (data && data.length > 0) {
        setStaff(data);
        setSelectedStaffId(data[0].id);
      }
      setError(null);
    } catch (err) {
      console.error('Error loading staff:', err);
      setError('Failed to load staff members');
    } finally {
      setIsLoading(false);
    }
  };

  const loadSchedule = async () => {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() + (currentWeekIndex * 7));
      const endDate = new Date(startDate);
      endDate.setDate(endDate.getDate() + 6);

      const days = await scheduleAPI.getStaffSchedule(
        selectedStaffId,
        startDate.toISOString().split('T')[0],
        endDate.toISOString().split('T')[0]
      );

      setWeekSchedule(days);
      setError(null);
    } catch (err) {
      console.error('Error loading schedule:', err);
      setError('Failed to load schedule');
    }
  };

  const handleTimeSlotAdd = async (date: string, slot: TimeSlot) => {
    try {
      await scheduleAPI.addTimeSlot(selectedStaffId, date, slot);
      await loadSchedule();
      setError(null);
    } catch (err) {
      console.error('Error adding time slot:', err);
      setError('Failed to add time slot');
    }
  };

  const handleTimeSlotRemove = async (date: string, slot: TimeSlot) => {
    try {
      const schedule = weekSchedule.find(day => day.date === date);
      if (schedule) {
        // Find the slot ID from the schedule
        const slotToRemove = schedule.timeSlots.find(
          s => s.start === slot.start && s.end === slot.end
        );
        if (slotToRemove) {
          await scheduleAPI.removeTimeSlot(schedule.id, slotToRemove.id);
          await loadSchedule();
          setError(null);
        }
      }
    } catch (err) {
      console.error('Error removing time slot:', err);
      setError('Failed to remove time slot');
    }
  };

  const handleToggleWorkingDay = async (date: string, isWorking: boolean) => {
    try {
      await scheduleAPI.setWorkingDay(selectedStaffId, date, isWorking);
      await loadSchedule();
      setError(null);
    } catch (err) {
      console.error('Error toggling working day:', err);
      setError('Failed to update working day');
    }
  };

  const handlePrevWeek = () => {
    setCurrentWeekIndex(prev => prev - 1);
  };

  const handleNextWeek = () => {
    setCurrentWeekIndex(prev => prev + 1);
  };

  if (isLoading) {
    return (
      <MainLayout title="Schedule Management">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout title="Schedule Management">
      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative">
          {error}
        </div>
      )}
      
      <ScheduleCalendar
        staff={staff}
        selectedStaffId={selectedStaffId}
        weekSchedule={weekSchedule}
        onTimeSlotAdd={handleTimeSlotAdd}
        onTimeSlotRemove={handleTimeSlotRemove}
        onToggleWorkingDay={handleToggleWorkingDay}
        onPrevWeek={handlePrevWeek}
        onNextWeek={handleNextWeek}
      />
    </MainLayout>
  );
};

export default SchedulePage;
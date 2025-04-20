import React, { useState } from 'react';
import { ChevronLeft, ChevronRight, Plus, X } from 'lucide-react';
import { DaySchedule, StaffMember, TimeSlot } from '../../types';

type ScheduleCalendarProps = {
  staff: StaffMember[];
  selectedStaffId: string;
  weekSchedule: DaySchedule[];
  onTimeSlotAdd: (date: string, slot: TimeSlot) => void;
  onTimeSlotRemove: (date: string, slot: TimeSlot) => void;
  onToggleWorkingDay: (date: string, isWorking: boolean) => void;
  onPrevWeek: () => void;
  onNextWeek: () => void;
};

const ScheduleCalendar: React.FC<ScheduleCalendarProps> = ({
  staff,
  selectedStaffId,
  weekSchedule,
  onTimeSlotAdd,
  onTimeSlotRemove,
  onToggleWorkingDay,
  onPrevWeek,
  onNextWeek
}) => {
  const [newSlotDate, setNewSlotDate] = useState<string | null>(null);
  const [newStartTime, setNewStartTime] = useState('09:00');
  const [newEndTime, setNewEndTime] = useState('10:00');
  
  const selectedStaff = staff.find(s => s.id === selectedStaffId);
  
  const getDayLabel = (dayOfWeek: number) => {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  };
  
  const handleAddTimeSlot = (date: string) => {
    if (newStartTime && newEndTime) {
      onTimeSlotAdd(date, {
        start: newStartTime,
        end: newEndTime
      });
      setNewSlotDate(null);
    }
  };
  
  return (
    <div className="bg-white rounded-xl shadow-sm overflow-hidden">
      <div className="p-6 border-b border-gray-200">
        <div className="flex justify-between items-center mb-4">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Schedule</h3>
            <p className="text-sm text-gray-500">
              {selectedStaff ? `${selectedStaff.name}'s availability` : 'Select a staff member'}
            </p>
          </div>
          
          <div className="flex items-center space-x-2">
            <select 
              className="border border-gray-300 rounded-md text-sm px-3 py-1.5"
              value={selectedStaffId}
              onChange={(e) => {/* Handle staff change */}}
            >
              {staff.map(member => (
                <option key={member.id} value={member.id}>
                  {member.name}
                </option>
              ))}
            </select>
            
            <div className="flex items-center ml-4">
              <button
                onClick={onPrevWeek}
                className="p-1.5 rounded-l-md border border-gray-300 hover:bg-gray-100"
              >
                <ChevronLeft size={16} />
              </button>
              <button
                onClick={onNextWeek}
                className="p-1.5 rounded-r-md border-t border-r border-b border-gray-300 hover:bg-gray-100"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-7 bg-gray-50">
        {weekSchedule.map((day, index) => (
          <div 
            key={day.date} 
            className={`p-2 text-center text-sm ${index === 0 || index === 6 ? 'bg-gray-100' : ''}`}
          >
            <div className="font-medium">{getDayLabel(day.dayOfWeek)}</div>
            <div className="text-gray-500">
              {new Date(day.date).getDate()}
            </div>
          </div>
        ))}
      </div>
      
      <div className="grid grid-cols-7 divide-x divide-gray-200">
        {weekSchedule.map((day) => (
          <div key={day.date} className="min-h-[300px] p-2 relative">
            <div className="mb-2 flex justify-between items-center">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={day.isWorking}
                  onChange={(e) => onToggleWorkingDay(day.date, e.target.checked)}
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <span className="text-xs ml-1.5">Working</span>
              </div>
              
              {day.isWorking && (
                <button
                  onClick={() => setNewSlotDate(day.date)}
                  className="p-1 text-blue-600 hover:text-blue-800 rounded"
                >
                  <Plus size={16} />
                </button>
              )}
            </div>
            
            {day.isWorking ? (
              <div className="space-y-1.5">
                {day.timeSlots.map((slot, idx) => (
                  <div 
                    key={idx}
                    className="bg-blue-100 p-1.5 rounded text-xs flex justify-between items-center"
                  >
                    <span className="text-blue-800">
                      {slot.start} - {slot.end}
                    </span>
                    <button
                      onClick={() => onTimeSlotRemove(day.date, slot)}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      <X size={14} />
                    </button>
                  </div>
                ))}
                
                {newSlotDate === day.date && (
                  <div className="bg-white p-2 border border-blue-300 rounded shadow-sm">
                    <div className="grid grid-cols-2 gap-1 mb-2">
                      <div>
                        <label className="block text-xs text-gray-600">Start</label>
                        <input
                          type="time"
                          value={newStartTime}
                          onChange={(e) => setNewStartTime(e.target.value)}
                          className="w-full text-xs border border-gray-300 rounded p-1"
                        />
                      </div>
                      <div>
                        <label className="block text-xs text-gray-600">End</label>
                        <input
                          type="time"
                          value={newEndTime}
                          onChange={(e) => setNewEndTime(e.target.value)}
                          className="w-full text-xs border border-gray-300 rounded p-1"
                        />
                      </div>
                    </div>
                    <div className="flex space-x-1">
                      <button
                        onClick={() => handleAddTimeSlot(day.date)}
                        className="bg-blue-600 text-white text-xs py-1 px-2 rounded flex-1"
                      >
                        Add
                      </button>
                      <button
                        onClick={() => setNewSlotDate(null)}
                        className="border border-gray-300 text-gray-700 text-xs py-1 px-2 rounded"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="h-full flex items-center justify-center">
                <span className="text-gray-400 text-xs">Day Off</span>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default ScheduleCalendar;
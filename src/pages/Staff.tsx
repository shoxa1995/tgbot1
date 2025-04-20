import React, { useState, useEffect } from 'react';
import MainLayout from '../components/Layout/MainLayout';
import StaffList from '../components/Staff/StaffList';
import StaffForm from '../components/Staff/StaffForm';
import { StaffMember } from '../types';
import { staffAPI } from '../lib/staff-api';
import { useAuthStore } from '../lib/auth-store';

const StaffPage: React.FC = () => {
  const [staff, setStaff] = useState<StaffMember[]>([]);
  const [isFormVisible, setIsFormVisible] = useState(false);
  const [editingStaff, setEditingStaff] = useState<StaffMember | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const user = useAuthStore(state => state.user);
  
  useEffect(() => {
    loadStaff();
  }, []);
  
  const loadStaff = async () => {
    try {
      setIsLoading(true);
      const data = await staffAPI.getStaff();
      setStaff(data);
      setError(null);
    } catch (err) {
      setError('Failed to load staff members');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleAddStaff = () => {
    setEditingStaff(null);
    setIsFormVisible(true);
  };
  
  const handleEditStaff = (staffId: string) => {
    const staffToEdit = staff.find(s => s.id === staffId);
    if (staffToEdit) {
      setEditingStaff(staffToEdit);
      setIsFormVisible(true);
    }
  };
  
  const handleDeleteStaff = async (staffId: string) => {
    if (confirm('Are you sure you want to delete this staff member? This action cannot be undone.')) {
      try {
        await staffAPI.deleteStaff(staffId);
        setStaff(staff.filter(s => s.id !== staffId));
      } catch (err) {
        setError('Failed to delete staff member');
        console.error(err);
      }
    }
  };
  
  const handleFormSubmit = async (formData: Omit<StaffMember, 'id'>) => {
    try {
      if (editingStaff) {
        const updated = await staffAPI.updateStaff(editingStaff.id, formData);
        setStaff(staff.map(s => s.id === editingStaff.id ? updated : s));
      } else {
        const created = await staffAPI.createStaff(formData);
        setStaff([created, ...staff]);
      }
      
      setIsFormVisible(false);
      setEditingStaff(null);
      setError(null);
    } catch (err) {
      setError(editingStaff ? 'Failed to update staff member' : 'Failed to create staff member');
      console.error(err);
    }
  };
  
  const handleFormCancel = () => {
    setIsFormVisible(false);
    setEditingStaff(null);
  };
  
  if (isLoading) {
    return (
      <MainLayout title="Staff Management">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </MainLayout>
    );
  }
  
  return (
    <MainLayout title="Staff Management">
      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded relative">
          {error}
        </div>
      )}
      
      {isFormVisible ? (
        <StaffForm
          staff={editingStaff || undefined}
          onSubmit={handleFormSubmit}
          onCancel={handleFormCancel}
        />
      ) : (
        <StaffList
          staff={staff}
          onEdit={handleEditStaff}
          onDelete={handleDeleteStaff}
          onAdd={handleAddStaff}
        />
      )}
    </MainLayout>
  );
};

export default StaffPage;
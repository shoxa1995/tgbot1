import React from 'react';
import MainLayout from '../components/Layout/MainLayout';
import IntegrationCard from '../components/Settings/IntegrationCard';
import { Zap, Video, Calendar, CreditCard } from 'lucide-react';

const SettingsPage: React.FC = () => {
  return (
    <MainLayout title="Settings">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <IntegrationCard
          title="Zoom"
          description="Connect your Zoom account to automatically create meetings for bookings."
          icon={<Video size={24} />}
          status="connected"
          onConnect={() => {}}
          onDisconnect={() => {}}
          extraInfo={
            <div className="text-sm text-gray-700">
              <div className="font-medium mb-1">Connected Account</div>
              <div>company@example.com</div>
            </div>
          }
        />
        
        <IntegrationCard
          title="Bitrix24"
          description="Sync bookings with your Bitrix24 calendar for staff scheduling."
          icon={<Calendar size={24} />}
          status="connected"
          onConnect={() => {}}
          onDisconnect={() => {}}
          extraInfo={
            <div className="text-sm text-gray-700">
              <div className="font-medium mb-1">Webhook URL</div>
              <div className="font-mono text-xs bg-gray-100 p-1.5 rounded overflow-x-auto">
                https://example.bitrix24.com/rest/1/abc123xyz/
              </div>
            </div>
          }
        />
        
        <IntegrationCard
          title="Click.uz Payments"
          description="Accept payments through Click.uz payment gateway."
          icon={<CreditCard size={24} />}
          status="disconnected"
          onConnect={() => {}}
          onDisconnect={() => {}}
        />
        
        <IntegrationCard
          title="Telegram Bot"
          description="Configure your Telegram bot settings and webhook."
          icon={<Zap size={24} />}
          status="connected"
          onConnect={() => {}}
          onDisconnect={() => {}}
          extraInfo={
            <div className="space-y-2 text-sm text-gray-700">
              <div>
                <div className="font-medium">Bot Username</div>
                <div>@YourBookingBot</div>
              </div>
              <div>
                <div className="font-medium">Webhook URL</div>
                <div className="font-mono text-xs bg-gray-100 p-1.5 rounded overflow-x-auto">
                  https://booking.example.com/api/webhook/telegram
                </div>
              </div>
            </div>
          }
        />
      </div>
      
      <div className="mt-8 bg-white rounded-xl shadow-sm p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Bot Settings</h3>
        
        <div className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Maximum Meeting Duration (minutes)
            </label>
            <input
              type="number"
              defaultValue={60}
              min={15}
              step={15}
              className="w-full max-w-xs rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Advance Booking Window (days)
            </label>
            <input
              type="number"
              defaultValue={14}
              min={1}
              className="w-full max-w-xs rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Default Welcome Message
            </label>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-2">
              <div>
                <label className="block text-xs text-gray-600 mb-1">English</label>
                <textarea
                  defaultValue="Welcome to our booking bot! Please select your language to get started."
                  rows={3}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-600 mb-1">Russian</label>
                <textarea
                  defaultValue="Добро пожаловать в наш бот для бронирования! Пожалуйста, выберите язык, чтобы начать."
                  rows={3}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-xs text-gray-600 mb-1">Uzbek</label>
                <textarea
                  defaultValue="Bizning bron qilish botimizga xush kelibsiz! Boshlash uchun tilni tanlang."
                  rows={3}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
          </div>
        </div>
        
        <div className="mt-8 flex justify-end">
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors">
            Save Settings
          </button>
        </div>
      </div>
    </MainLayout>
  );
};

export default SettingsPage;
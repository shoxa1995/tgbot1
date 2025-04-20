import React from 'react';
import { CheckCircle, XCircle } from 'lucide-react';

type IntegrationCardProps = {
  title: string;
  description: string;
  icon: React.ReactNode;
  status: 'connected' | 'disconnected' | 'pending';
  onConnect: () => void;
  onDisconnect: () => void;
  extraInfo?: React.ReactNode;
};

const IntegrationCard: React.FC<IntegrationCardProps> = ({
  title,
  description,
  icon,
  status,
  onConnect,
  onDisconnect,
  extraInfo
}) => {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex items-center mb-4">
        <div className="bg-blue-50 p-3 rounded-lg text-blue-600 mr-4">
          {icon}
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
          <p className="text-sm text-gray-500">{description}</p>
        </div>
      </div>
      
      <div className="flex items-center justify-between mt-6">
        <div className="flex items-center">
          {status === 'connected' ? (
            <>
              <CheckCircle size={18} className="text-green-600 mr-2" />
              <span className="text-sm font-medium text-green-600">Connected</span>
            </>
          ) : status === 'pending' ? (
            <>
              <div className="h-4 w-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin mr-2"></div>
              <span className="text-sm font-medium text-blue-600">Connecting...</span>
            </>
          ) : (
            <>
              <XCircle size={18} className="text-red-600 mr-2" />
              <span className="text-sm font-medium text-red-600">Disconnected</span>
            </>
          )}
        </div>
        
        {status === 'connected' ? (
          <button 
            onClick={onDisconnect}
            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
          >
            Disconnect
          </button>
        ) : (
          <button 
            onClick={onConnect}
            className="px-3 py-1.5 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
            disabled={status === 'pending'}
          >
            {status === 'pending' ? 'Connecting...' : 'Connect'}
          </button>
        )}
      </div>
      
      {extraInfo && (
        <div className="mt-4 p-3 bg-gray-50 rounded-lg border border-gray-200">
          {extraInfo}
        </div>
      )}
    </div>
  );
};

export default IntegrationCard;
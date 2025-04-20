import React from 'react';
import { ArrowUpRight, ArrowDownRight } from 'lucide-react';

type StatsCardProps = {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  change?: number;
  changeTimeframe?: string;
};

const StatsCard: React.FC<StatsCardProps> = ({ 
  title, 
  value, 
  icon, 
  change = 0, 
  changeTimeframe = 'from last week' 
}) => {
  const isPositive = change >= 0;
  
  return (
    <div className="bg-white rounded-xl shadow-sm p-6 flex flex-col">
      <div className="flex justify-between items-start mb-4">
        <h3 className="text-gray-500 font-medium text-sm">{title}</h3>
        <div className="p-2 rounded-lg bg-blue-50 text-blue-600">
          {icon}
        </div>
      </div>
      
      <div className="mt-2">
        <div className="text-2xl font-bold text-gray-900">{value}</div>
        
        {change !== undefined && (
          <div className="flex items-center mt-2">
            <div className={`flex items-center ${isPositive ? 'text-green-600' : 'text-red-600'}`}>
              {isPositive ? (
                <ArrowUpRight size={16} className="mr-1" />
              ) : (
                <ArrowDownRight size={16} className="mr-1" />
              )}
              <span className="text-sm font-medium">{Math.abs(change)}%</span>
            </div>
            <span className="text-sm text-gray-500 ml-1">{changeTimeframe}</span>
          </div>
        )}
      </div>
    </div>
  );
};

export default StatsCard;
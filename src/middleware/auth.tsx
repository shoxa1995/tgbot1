import { useAuthStore } from '../lib/auth-store';
import { Navigate } from 'react-router-dom';
import { ReactElement } from 'react';

interface AuthProps {
  children: ReactElement;
}

export function RequireAuth({ children }: AuthProps): ReactElement {
  const user = useAuthStore((state) => state.user);

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return children;
}

export function RequireAdmin({ children }: AuthProps): ReactElement {
  const user = useAuthStore((state) => state.user);

  if (!user || user.role !== 'admin') {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
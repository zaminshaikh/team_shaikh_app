// ProtectedRoute.tsx
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuthState } from 'react-firebase-hooks/auth'; // You may need to install react-firebase-hooks
import { auth } from './App'; // Adjust the path as necessary
import { CSpinner } from '@coreui/react-pro';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
    // auth.signOut();
    const [user, loading, error] = useAuthState(auth);
    const location = useLocation();

    if (loading) {
        return (<div className="text-center">
            <CSpinner color="primary"/>
        </div>);
    }

    if (error) {
        console.error('Error fetching auth state:', error);
        return <Navigate to="/500" state={{ from: location }} replace />
    }

    return user ? (
        children
    ) : (
        <Navigate to="/login" state={{ from: location }} replace />
    );
};

export default ProtectedRoute;

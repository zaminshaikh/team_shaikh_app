import React from 'react';
import { CModal, CModalHeader, CModalTitle, CModalBody, CModalFooter, CButton, CToast, CToastBody, CToastHeader } from '@coreui/react-pro';
import { faExclamationTriangle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { Activity, DatabaseService, formatCurrency, ScheduledActivity } from 'src/db/database';

interface DeleteActivityProps {
    showModal: boolean;
    setShowModal: (show: boolean) => void;
    activity?: Activity; 
    selectedClient?: string | number;
    setAllActivities?: (activites: Activity[]) => void | undefined;
    setFilteredActivities?: (activites: Activity[]) => void | undefined;
    setScheduledActivities?: (activites: ScheduledActivity[]) => void | undefined;
    isScheduled?: boolean; // <-- Add this
}

const DeleteActivity: React.FC<DeleteActivityProps> = ({showModal, setShowModal, activity, selectedClient, setScheduledActivities, setAllActivities, setFilteredActivities, isScheduled}) => {
    const db = new DatabaseService();

    const deleteActivity = async () => {
        if (activity && activity.id) {
            try {
                if (isScheduled && setScheduledActivities) {
                    await db.deleteScheduledActivity(activity.id);
                    setShowModal(false);
                    const scheduledActivities = await db.getScheduledActivities(); // Get the new updated activities
                    setScheduledActivities(scheduledActivities);
                    return;
                } else if (setAllActivities) {
                    await db.deleteActivity(activity);
                    await db.deleteNotification(activity);
                    setShowModal(false);
                    const activities = await db.getActivities(); // Get the new updated activities
                    setAllActivities(activities);
                    // Filter by the client we just deleted an activity for
                    if (selectedClient && setFilteredActivities) {
                        setFilteredActivities(activities.filter((activities) => activities.parentDocId === selectedClient));
                    } else if (setFilteredActivities) {
                        setFilteredActivities(activities);
                    }
                }
                // addToast(exampleToast);
            } catch (error) {
                console.error('Failed to delete activity:', error);
            }
        }
    };

    return (
        <CModal         
            scrollable
            alignment="center"
            visible={showModal} 
            backdrop="static" 
            size="lg"
            onClose={() => setShowModal(false)}>
            <CModalHeader>
                <CModalTitle style={{fontSize: '2rem'}}>
                    <FontAwesomeIcon className="me-2" icon={faExclamationTriangle} color="red" /> Delete Activity?
                </CModalTitle>
            </CModalHeader>
            <CModalBody className="px-5">
    <div className="py-3">
        <strong className="d-block mb-3">You are about to delete the activity with the following details:</strong>
        <div className="mb-2">
            <strong>Recipient:</strong> <span>{activity?.recipient as string}</span>
        </div>
        <div className="mb-2">
            <strong>Time:</strong> <span>{activity?.formattedTime as string}</span>
        </div>
        <div className="mb-2">
            <strong>Amount:</strong> <span>{formatCurrency(activity?.amount as number)}</span>
        </div>
        <div className="mb-2">
            <strong>Type:</strong> <span>{activity?.type as string}</span>
        </div>
        <div className="mb-2">
            <strong>Fund:</strong> <span>{activity?.fund as string}</span>
        </div>
        <strong className="d-block mt-3 text-danger">THIS ACTION IS IRREVERSIBLE.</strong>
    </div>
            </CModalBody>
            <CModalFooter>
                <CButton color="secondary" onClick={() => setShowModal(false)}>Cancel</CButton>
                <CButton color="danger" variant="outline"
                    onClick={() => deleteActivity()}>Delete</CButton>
            </CModalFooter>
        </CModal>
    );
};

export default DeleteActivity;
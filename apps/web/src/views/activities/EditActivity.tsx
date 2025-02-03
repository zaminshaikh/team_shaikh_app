import React, { act, useEffect, useState } from 'react';
import { CModal, CModalHeader, CModalTitle, CModalFooter, CButton } from '@coreui/react-pro';
import { DatabaseService, Activity, emptyActivity, Client, emptyClient, ScheduledActivity } from 'src/db/database';
import { ValidateActivity, ActivityInputModalBody } from './ActivityInputModalBody';
import { FormValidationErrorModal } from '../../components/ErrorModal';
import { amortize } from 'src/utils/utilities';

interface EditActivityProps {
    showModal: boolean;
    setShowModal: (show: boolean) => void;
    clients: Client[]; 
    activity?: Activity;
    selectedClient?: string | number;
    setAllActivities?: (activites: Activity[]) => void | undefined;
    setScheduledActivities?: (activites: ScheduledActivity[]) => void | undefined;  
    setFilteredActivities?: (activites: Activity[]) => void | undefined;
    onSubmit?: (updatedActivity: Activity) => void;
    isScheduled?: boolean; // <-- Add this
}

// const editScheduledActivity = async () => {
//     if (activity) {
//         try {
//             if (isScheduled && activity.id) {
//                 const scheduledToUpdate = { ...someScheduledActivityData, id: activity.id }; 
//                 await db.updateScheduledActivity(scheduledToUpdate);
//             } else {
//                 // ...existing logic for regular activities...
//             }
//             // ...existing code...
//         } catch (error) {
//             // ...existing code...
//         }
//     }
// };

const handleEditActivity = async (activityState: Activity, clientState: Client, isScheduled: boolean) => {
    const db = new DatabaseService();

    if (activityState.isAmortization === true && !activityState.amortizationCreated) {

        let promises = [];
        const [profit, withdrawal] = amortize(activityState, clientState);
        if (isScheduled) {
 
            promises.push(db.scheduleActivity(profit, clientState));
            promises.push(db.scheduleActivity(withdrawal, clientState));
            promises.push(db.deleteScheduledActivity(activityState.id!));
            
        } else {
            promises.push(db.createActivity(profit, clientState.cid));
            promises.push(db.createActivity(withdrawal, clientState.cid));
            promises.push(db.deleteActivity(activityState));
            promises.push(db.setAssets(clientState));
        }

        await Promise.all(promises);
        return;
    } else if (isScheduled && activityState.id) {
        await db.updateScheduledActivity(activityState, clientState);
        return;
    }
    
    // Create activity with client cid
    await db.setActivity(activityState, {activityDocId: activityState.id}, clientState!.cid);

    if ((activityState.isDividend || activityState.type === 'manual-entry'|| activityState.type === 'deposit' || activityState.type === 'withdrawal') && clientState) {
        await db.setAssets(clientState);
    }
}

const EditActivity: React.FC<EditActivityProps> = ({ showModal, setShowModal, clients, activity, selectedClient, setAllActivities, setFilteredActivities, setScheduledActivities,onSubmit=handleEditActivity, isScheduled=false}) => {
    const db = new DatabaseService();
    
    const [activityState, setActivityState] = useState<Activity>(activity ?? emptyActivity);
    const [clientState, setClientState] = useState<Client | null>(emptyClient);
    const [showErrorModal, setShowErrorModal] = useState(false);
    const [invalidInputFields, setInvalidInputFields] = useState<string[]>([]);
    const [override, setOverride] = useState(false);
    
    const clientOptions = clients!
    .map(client => ({value: client.cid, label: client.firstName + ' ' + client.lastName, selected: activity?.parentDocId === client.cid }))
    .sort((a, b) => a.label.localeCompare(b.label));;
    
    useEffect(() => {
        const editActivityIfOverride = async () => {
            if (override) {
                if (!ValidateActivity(activityState, setInvalidInputFields)) {
                    setShowErrorModal(true);
                    return;
                }
                
                if (override) {
                    setActivityState({
                        ...activityState,
                        time: new Date(),
                    });
                }
                
                if (!clientState) {
                    console.error("Invalid client state");
                    return;
                }
                
                await handleEditActivity(activityState, clientState, isScheduled);
                
                setShowModal(false);
                const activities = await db.getActivities(); // Get the new updated activities
                if (setAllActivities) {
                    setAllActivities(activities);
                }
                // Filter by the client we just edited an activity for
                if (setFilteredActivities) {
                    setFilteredActivities(activities.filter((activities) => activities.parentDocId === (selectedClient ?? clientState.cid)));
                }
            }
        };
        editActivityIfOverride();
    }, [override]);
    
    useEffect(() => {
        const fetchClient = async () => {
            try {
                console.log('Fetching client:', activityState.parentDocId);
                const client = await db.getClient(activityState.parentDocId ?? '');
                setClientState(client);
                
            } catch (error) {
                console.error('Failed to fetch client:', error);
            }
        };
        fetchClient();
    }, []);
    

    console.log('Activity state changed:', activityState);
    return (
        <>
            {showErrorModal && <FormValidationErrorModal showErrorModal={showErrorModal} setShowErrorModal={setShowErrorModal} invalidInputFields={invalidInputFields} setOverride={setOverride}/>}
            <CModal 
                scrollable
                visible={showModal} 
                backdrop="static" 
                size="xl" 
                alignment="center"
                onClose={() => setShowModal(false)}>
                <CModalHeader closeButton>
                    <CModalTitle>Edit Activity</CModalTitle>
                </CModalHeader>
                <ActivityInputModalBody
                    activityState={activityState}
                    setActivityState={setActivityState}
                    clientState={clientState}
                    setClientState={setClientState}
                    clientOptions={clientOptions}            
                />
                <CModalFooter>
                    <CButton color="secondary" variant="outline" onClick={() => setShowModal(false)}>Cancel</CButton>
                    <CButton color="primary" onClick={ async () => {
                        if (!ValidateActivity(activityState, setInvalidInputFields)) {
                            setShowErrorModal(true);
                            return;
                        }

                        if (override) {
                            setActivityState({
                                ...activityState,
                                time: new Date(),
                            });
                        }

                        if (!clientState) {
                            console.error("Invalid client state");
                            return;
                        }
                        
                        await onSubmit(activityState, clientState, isScheduled);
                        
                        setShowModal(false);

                        if (setScheduledActivities) {
                            const scheduledActivities = await db.getScheduledActivities(); // Get the new updated activities
                            setScheduledActivities(scheduledActivities);
                        }
                        const activities = await db.getActivities(); // Get the new updated activities
                        if (setAllActivities) {
                            setAllActivities(activities);
                        }
                        // Filter by the client we just edited an activity for
                        if (setFilteredActivities) {
                            setFilteredActivities(activities.filter((activities) => activities.parentDocId === (selectedClient ?? clientState.cid)));
                        }
                    }}>Update</CButton>
                </CModalFooter>
            </CModal>
        </>
        
    )
}


export default EditActivity;
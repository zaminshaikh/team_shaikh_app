import { CButton, CModal, CModalBody, CModalFooter, CModalHeader, CModalTitle} from "@coreui/react-pro"
import { act, useEffect, useState } from "react";
import React from "react";
import { Activity, DatabaseService, Client, emptyActivity, emptyClient, ScheduledActivity } from '../../db/database.ts'
import { ActivityInputModalBody } from "./ActivityInputModalBody.tsx";
import { ValidateActivity } from "./ActivityInputModalBody.tsx";
import { FormValidationErrorModal } from '../../components/ErrorModal';
import Activities from './Activities';
import CIcon from '@coreui/icons-react';
import { cilCalendar, cilPlus, cilTrash } from '@coreui/icons';
import { amortize } from "src/utils/utilities.ts";


interface ShowModalProps {
    showModal: boolean;
    setShowModal: (show: boolean) => void;
    clients?: Client[];
    selectedClient?: string | number;
    setAllActivities: (activites: Activity[]) => void;
    setFilteredActivities: (activites: Activity[]) => void;
    setScheduledActivities: (activites: ScheduledActivity[]) => void;
}


export const CreateActivity: React.FC<ShowModalProps> = ({showModal, setShowModal, clients, selectedClient, setAllActivities, setFilteredActivities, setScheduledActivities}) => {
    const db = new DatabaseService();
    const [activityState, setActivityState] = useState<Activity>(emptyActivity);
    const [clientState, setClientState] = useState<Client | null>(clients?.find(client => client.cid === selectedClient) ?? null);
    const [showErrorModal, setShowErrorModal] = useState(false);
    const [invalidInputFields, setInvalidInputFields] = useState<string[]>([]);
    const [override, setOverride] = useState(false);

    const clientOptions = clients!
        .map(client => ({value: client.cid, label: client.firstName + ' ' + client.lastName, selected: selectedClient === client.cid }))
        .sort((a, b) => a.label.localeCompare(b.label));
    
        
    const handleCreateActivity = async () => {
        if (!ValidateActivity(activityState, setInvalidInputFields) && !override) {
            setShowErrorModal(true);
        } else {
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

            if (activityState.isAmortization === true && !activityState.amortizationCreated) {
                
                const [profit, withdrawal] = amortize(activityState, clientState);    

                let promises = [];
                promises.push(db.createActivity(profit, clientState.cid));
                promises.push(db.createActivity(withdrawal, clientState.cid));
                promises.push(db.setAssets(clientState));

                await Promise.all(promises);
            } else {
                // Create activity with client cid
                await db.createActivity({...activityState, parentName: clientState.firstName + ' ' + clientState.lastName}, clientState.cid);
                if ((activityState.isDividend || activityState.type === 'manual-entry'|| activityState.type === 'deposit' || activityState.type === 'withdrawal') && clientState) {
                    await db.setAssets(clientState);
                }
            }
            setShowModal(false);
            const activities = await db.getActivities(); // Get the new updated activities
            setAllActivities(activities)
            // Filter by the client we just created an activity for
            setFilteredActivities(activities.filter((activities) => activities.parentDocId === (selectedClient ?? clientState.cid)));
        }
    }

    const handleScheduleActivity = async () => {
        if (!ValidateActivity(activityState, setInvalidInputFields) && !override) {
            setShowErrorModal(true);
        } else {
            if (override) {
                setActivityState({
                    ...activityState,
                    time: new Date(),
                });
            }
            if (activityState.time <= new Date()) {
                alert("Scheduled time must be in the future.");
                return;
            }

            if (!clientState) {
                console.error("Invalid client state");
                return;
            }
            
            if (activityState.isAmortization === true && !activityState.amortizationCreated) {
                    
                const [profit, withdrawal] = amortize(activityState, clientState); 

                await db.scheduleActivity(profit, clientState);
                await db.scheduleActivity(withdrawal, clientState);

            } else {
                await db.scheduleActivity(activityState, clientState);
            }
            setShowModal(false);
            const activities = await db.getActivities(); // Get the new updated activities
            setAllActivities(activities)
            const scheduledActivities = await db.getScheduledActivities(); // Get the new updated activities
            setScheduledActivities(scheduledActivities);
            // Filter by the client we just created an activity for
            setFilteredActivities(activities.filter((activities) => activities.parentDocId === (selectedClient ?? clientState.cid)));
        }
    };

    useEffect(() => {
        const createActivityIfOverride = async () => {
            if (override) {
                await handleCreateActivity();
            }
        };
        createActivityIfOverride();
    }, [override]);


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
                    <CModalTitle >Create New Activity</CModalTitle>
                </CModalHeader>
                <ActivityInputModalBody
                    activityState={activityState}
                    setActivityState={setActivityState}
                    clientState={clientState}
                    setClientState={setClientState}
                    clientOptions={clientOptions}            
                />
                <CModalFooter>
                    <CButton color="primary" onClick={handleCreateActivity}>
                        <CIcon icon={cilPlus} className="me-2" />
                        Create
                    </CButton>
                    <CButton color="primary" variant="outline" onClick={handleScheduleActivity}>
                        <CIcon icon={cilCalendar} className="me-2" />
                        Schedule
                    </CButton>
                    <CButton color="danger" variant="outline" onClick={() => {setShowModal(false)}}>
                        <CIcon icon={cilTrash} className="me-2" />
                        Discard
                    </CButton>
                </CModalFooter>
            </CModal>
        </>
        
    )
}


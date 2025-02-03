import { useTranslation } from "react-i18next";
import ActivitiesTable from "./ActivitiesTable";
import { useEffect, useState } from "react";
import { DatabaseService, Client, ScheduledActivity, Activity } from "src/db/database";
import { CButton, CSpinner } from "@coreui/react-pro";
import ScheduledActivitiesTable from "./ScheduledActivitiesTable";
import { CreateActivity } from "./CreateActivity";

const Activities = () => {
    const { t } = useTranslation()
    const [showCreateActivityModal, setShowCreateActivityModal] = useState(false);

    const [allActivities, setAllActivities] = useState<Activity[]>([]); // New state for original activities
    const [filteredActivities, setFilteredActivities] = useState<Activity[]>([]);
    const [scheduledActivities, setScheduledActivities] = useState<ScheduledActivity[]>([]); // New state for original activities
    
    const [clients, setClients] = useState<Client[]>([]);
    const [selectedClient, setSelectedClient] = useState<string | number>(); 

    return (
        <div>
            {showCreateActivityModal && 
            <CreateActivity 
                showModal={showCreateActivityModal} 
                setShowModal={setShowCreateActivityModal} 
                clients={clients} 
                selectedClient={selectedClient} 
                setAllActivities={setAllActivities} 
                setFilteredActivities={setFilteredActivities}
                setScheduledActivities={setScheduledActivities}
            />}
            <div className="d-grid gap-2 py-3">
                <CButton color='primary' onClick={() => setShowCreateActivityModal(true)}>Add Activity +</CButton>
            </div> 
            <ActivitiesTable 
                allActivities={allActivities}
                setAllActivities={setAllActivities}
                filteredActivities={filteredActivities}
                setFilteredActivities={setFilteredActivities}
                clients={clients}
                setClients={setClients}
                selectedClient={selectedClient}
                setSelectedClient={setSelectedClient}
            />
            <ScheduledActivitiesTable 
                scheduledActivities={scheduledActivities} 
                setScheduledActivities={setScheduledActivities}
            />
        </div>
    );
};

export default Activities;
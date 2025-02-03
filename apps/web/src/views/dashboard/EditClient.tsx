import { CButton, CLoadingButton, CModal, CModalFooter, CModalHeader, CModalTitle } from "@coreui/react-pro"
import { useEffect, useState } from "react";
// import { IMaskMixin } from 'react-imask'
import React from "react";
import { DatabaseService, Client, emptyClient } from '../../db/database.ts'
import { ClientInputModalBody, ValidateClient } from './ClientInputModalBody.tsx'
import { FormValidationErrorModal } from '../../components/ErrorModal';
import { Option, OptionsGroup } from '@coreui/react-pro/dist/esm/components/multi-select/types';

// const CFormInputWithMask = React.forwardRef<HTMLInputElement, any>((props, ref) => (
//     <CFormInput
//         {...props}
//         ref={ref} // bind internal input
//     />
// ))

// const MaskedInput = IMaskMixin(CFormInputWithMask);

// State variable, determines if modal is shown based on ClientsTable.tsx state
interface ShowModalProps {
        showModal: boolean;
        setShowModal: (show: boolean) => void;
        clients?: Client[];
        setClients: (clients: Client[]) => void;
        activeClient?: Client;
        onSubmit?: (updatedClient: Client) => void;
        reload?: boolean;
}

// Default onSubmit function
const handleEditClient = async (clientState: Client, override: boolean, setClientState: (clientState: Client) => void) => {
        if (override) {
            setClientState({
                ...clientState,
                dob: null,
                firstDepositDate: null,
            });
        }
        // If validation passes, create the client and reload the page
        const db = new DatabaseService();
        await db.updateClient(clientState);
};

// TODO: Perform validation on address and email
// Initial modal to create new client
export const EditClient: React.FC<ShowModalProps> = ({showModal, setShowModal, clients: clients, setClients, activeClient: activeClient, onSubmit=handleEditClient, reload=true}) => {
    // Initialize the client state
    const initialClientState: Client = {...activeClient ?? emptyClient};
    const [clientState, setClientState] = useState<Client>(initialClientState);
    const [isLoading, setIsLoading] = useState(false);

    const [showErrorModal, setShowErrorModal] = useState(false);
    const [clientOptions, setClientOptions] = useState<(Option | OptionsGroup)[]>(clients!.map(client => ({value: client.cid, label: client.firstName + ' ' + client.lastName, selected: (activeClient?.connectedUsers?.includes(client.cid))})))
    const [invalidInputFields, setInvalidInputFields] = useState<string[]>([]);
    const [override, setOverride] = useState(false);

    useEffect(() => {
        const editClientIfOverride = async () => {
            if (override) {
                await onSubmit(clientState, override, setClientState);
                const db = new DatabaseService();
                setShowModal(false);
                const updatedClients = await db.getClients()
                setClients(updatedClients);
            }
        };
        editClientIfOverride();
    }, [override]);

    return (
        
        <div>
            {showErrorModal && <FormValidationErrorModal showErrorModal={showErrorModal} 
                setShowErrorModal={setShowErrorModal}
                invalidInputFields={invalidInputFields}
                setOverride={setOverride}/>} 
            <CModal 
                scrollable
                alignment="center"
                visible={showModal} 
                backdrop="static" 
                size="xl" 
                onClose={() => setShowModal(false)}>
                <CModalHeader>
                    <CModalTitle>Edit {activeClient?.firstName} {activeClient?.lastName}</CModalTitle>
                </CModalHeader>
                <ClientInputModalBody 
                    clientState={clientState} 
                    setClientState={setClientState} 
                    clientOptions={clientOptions}
                    setClientOptions={setClientOptions}
                    clients={clients}
                    viewOnly={false}/>
                <CModalFooter>
                    <CButton color="secondary" variant="outline" onClick={() => setShowModal(false)}>Cancel</CButton>
                    <CLoadingButton color="primary" 
                        loading={isLoading}
                        onClick={async () => {
                            setIsLoading(true);
                            if (!ValidateClient(clientState, setInvalidInputFields) && !override) {
                                setShowErrorModal(true);
                            } else {
                                onSubmit(clientState, override, setClientState);
                                const db = new DatabaseService();
                                const updatedClients = await db.getClients()
                                setClients(updatedClients);
                                setIsLoading(false);
                                setShowModal(false);
                                return;
                            }
                            setIsLoading(false);
                        }}
                        >Update</CLoadingButton>
                </CModalFooter>
            </CModal>
        </div>
    )
}

export default EditClient;
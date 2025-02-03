import { CButton, CModal, CModalHeader, CModalTitle, CModalFooter} from "@coreui/react-pro"
import { useEffect, useState } from "react";
import React from "react";
import { DatabaseService, Client, emptyClient } from '../../db/database.ts'
import { ClientInputModalBody } from "./ClientInputModalBody.tsx";
import { ValidateClient } from "./ClientInputModalBody.tsx";
import { FormValidationErrorModal } from '../../components/ErrorModal.tsx';
import { Option, OptionsGroup } from "@coreui/react-pro/dist/esm/components/multi-select/types";

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
}
// Initialize the client state
const initialClientState: Client = emptyClient

// TODO: Perform validation on address and email
// Initial modal to create new client
const CreateClient: React.FC<ShowModalProps> = ({showModal, setShowModal, clients, setClients}) => {
    const db = new DatabaseService();
    const [clientState, setClientState] = useState<Client>(initialClientState);

    const [showErrorModal, setShowErrorModal] = useState(false);
    const [clientOptions, setClientOptions] = useState<(Option | OptionsGroup)[]>(clients!.map(client => ({value: client.cid, label: client.firstName + ' ' + client.lastName})))
    const [invalidInputFields, setInvalidInputFields] = useState<string[]>([]);
    const [override, setOverride] = useState(false);

    const handleCreateClient = async () => {
        if (!ValidateClient(clientState, setInvalidInputFields) && !override) {
            // If validation fails, show error modal
            setShowErrorModal(true); 
        } else {
            if (override) {
                setClientState({
                    ...clientState,
                    dob: null,
                    firstDepositDate: null,
                });
            }
            // If validation passes, create the client and reload the page
            await db.createClient(clientState);
            setClients(await db.getClients());
            setShowModal(false);

        }
    }

    useEffect(() => {
        const createClientIfOverride = async () => {
            if (override) {
                await handleCreateClient();
            }
        };
        createClientIfOverride();
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
                    <CModalTitle>Create a New Client</CModalTitle>
                </CModalHeader>
                <ClientInputModalBody 
                    clientState={clientState} 
                    setClientState={setClientState} 
                    clientOptions={clientOptions}
                    setClientOptions={setClientOptions}
                    viewOnly={false}/>
                <CModalFooter>
                    <CButton color="danger" variant="outline" onClick={() => setShowModal(false)}>Discard</CButton>
                    <CButton color="primary" onClick={() => handleCreateClient()}>Create +</CButton>
                </CModalFooter>
            </CModal>
        </div>
    )
}

export default CreateClient;
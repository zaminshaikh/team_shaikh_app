import { CButton, CFormInput, CInputGroup, CInputGroupText, CModal, CModalBody, CModalFooter, CModalHeader, CModalTitle } from "@coreui/react-pro";
import { faExclamationTriangle } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useEffect, useState } from "react";
import { DatabaseService, Client } from "src/db/database";

interface ShowModalProps {
        showModal: boolean;
        setShowModal: (show: boolean) => void;
        client?: Client;
        setClients: (clients: Client[]) => void;
}

export const DeleteClient: React.FC<ShowModalProps> = ({showModal, setShowModal, client, setClients}) => {
    const service = new DatabaseService();
    const [firstName, setFirstName] = useState('');
    const [lastName, setLastName] = useState('');
    const [doNamesMatch, setDoNamesMatch] = useState(false);

    useEffect(() => {
        setDoNamesMatch(firstName === client?.firstName && lastName === client?.lastName);
    }, [firstName, lastName, client]);
    
    const deleteClient = async () => {
        await service.deleteClient(client?.cid)
        setClients(await service.getClients());
        setShowModal(false);
    }

    return (
        <CModal         
            scrollable
            alignment="center"
            visible={showModal} 
            backdrop="static" 
            size="lg" 
            onClose={() => setShowModal(false)}>
        <CModalHeader>
            <CModalTitle>
            <FontAwesomeIcon
                className="pr-2"
                icon={faExclamationTriangle}
                color="red"
            />{" "}
            WARNING
            </CModalTitle>
        </CModalHeader>
            <CModalBody className="px-5">
                You are about to delete the client {client?.firstName} {client?.lastName}. THIS ACTION IS IRREVERSIBLE. To delete this client, type their first and last name below:
                <div className="py-3">
                    <CInputGroup>
                        <CInputGroupText>Client's First Name</CInputGroupText>
                        <CFormInput onChange={(e) => {
                            setFirstName(e.target.value);
                        }}/>
                        <CInputGroupText>Client's Last Name</CInputGroupText>
                        <CFormInput onChange={(e) => {
                            setLastName(e.target.value);
                        }}/>
                    </CInputGroup>
                </div>
            </CModalBody>
            <CModalFooter>
                <CButton color="secondary" onClick={() => setShowModal(false)}>Cancel</CButton>
                <CButton color="danger" variant="outline" disabled={!doNamesMatch} 
                    onClick={() => deleteClient()}>Delete</CButton>
            </CModalFooter>
        </CModal>
    )
}
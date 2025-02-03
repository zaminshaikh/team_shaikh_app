import {
  CButton,
  CFormInput,
  CInputGroup,
  CInputGroupText,
  CLoadingButton,
  CModal,
  CModalBody,
  CModalFooter,
  CModalHeader,
  CModalTitle,
} from "@coreui/react-pro";
import { faExclamationTriangle } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { set } from "date-fns";
import { useEffect, useState } from "react";
import { Client, DatabaseService } from "src/db/database";


interface ShowModalProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  client?: Client;
  setClients: (users: Client[]) => void;
}

export const UnlinkClient: React.FC<ShowModalProps> = ({
  showModal,
  setShowModal,
  client,
  setClients,
}) => {
  const service = new DatabaseService();
  const [email, setEmail] = useState("");
  const [doEmailsMatch, setDoEmailsMatch] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    setDoEmailsMatch(email === client?.initEmail);
  }, [email, client]);

  const unlinkClient = async () => {
    console.log(client);
    if (client?.uid && client?.uid !== "" ) {
      setIsLoading(true);
      await service.unlinkClient(client);
      const updatedClients = await service.getClients();
      setClients(updatedClients);
      setIsLoading(false);
    } else {
      alert("Client has not signed up yet.");
    }
    setShowModal(false);
  };

  return (
    <CModal
      scrollable
      alignment="center"
      visible={showModal}
      backdrop="static"
      size="lg"
      onClose={() => setShowModal(false)}
    >
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
        You are about to unlink the client <strong>{client?.firstName} {client?.lastName}</strong> (
        {client?.initEmail}). THIS ACTION IS IRREVERSIBLE. To confirm, please type the
        client's email below:
        <div className="py-3">
          <CInputGroup>
            <CInputGroupText>Client's Email</CInputGroupText>
            <CFormInput
              placeholder="Enter client's email"
              onChange={(e) => {
                setEmail(e.target.value);
              }}
            />
          </CInputGroup>
        </div>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" onClick={() => setShowModal(false)}>
          Cancel
        </CButton>
        <CLoadingButton
          color="danger"
          variant="outline"
          disabled={!doEmailsMatch}
          loading={isLoading}
          onClick={() => unlinkClient()}
        >
          Unlink
        </CLoadingButton>
      </CModalFooter>
    </CModal>
  );
};
import { CModal, CModalHeader, CModalTitle, CModalBody, CModalFooter, CButton } from "@coreui/react-pro";
import { faExclamationTriangle } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

interface FormValidationErrorModalProps {
    showErrorModal: boolean,
    setShowErrorModal: (show: boolean) => void,
    invalidInputFields: string[],
    setOverride: (override: boolean) => void,
}

interface AuthErrorModalProps {
    message: string;
    showErrorModal: boolean;
    setShowErrorModal: (show: boolean) => void,
}

export const FormValidationErrorModal: React.FC<FormValidationErrorModalProps> = ({showErrorModal, setShowErrorModal, invalidInputFields, setOverride}) => {
    return (
        <CModal
            scrollable
            alignment="center"
            visible={showErrorModal} 
            backdrop="static" 
            onClose={() => setShowErrorModal(false)}
        >
            <CModalHeader>
                <CModalTitle>
                    <FontAwesomeIcon className="pr-5" icon={faExclamationTriangle} color="red" />  WARNING
                </CModalTitle>
            </CModalHeader>
            <CModalBody>
                <h5>The following fields have not been filled:</h5>
                <ul>
                    {invalidInputFields.map((message, index) => (
                        <li key={index}>{message}</li>
                    ))}
                </ul>
            </CModalBody>
            <CModalFooter>
                <CButton color="primary" onClick={() => {
                    setOverride(true);
                    setShowErrorModal(false);
                }}>Override & Proceed</CButton>

                <CButton color="secondary" onClick={() => {
                    setShowErrorModal(false);
                }}>Go Back</CButton>
            </CModalFooter>
        </CModal>
    )
}

export const AuthErrorModal: React.FC<AuthErrorModalProps> = ({message, showErrorModal, setShowErrorModal}) => {
    return (
        <CModal
            scrollable
            alignment="center"
            visible={showErrorModal} 
            backdrop="static" 
            onClose={() => setShowErrorModal(false)}
        >
            <CModalHeader>
                <CModalTitle>
                    <FontAwesomeIcon className="pr-5" icon={faExclamationTriangle} color="red" />  ERROR
                </CModalTitle>
            </CModalHeader>
            <CModalBody>
                {message}
            </CModalBody>
            <CModalFooter>
                <CButton color="primary" onClick={() => {
                    setShowErrorModal(false);
                }}>Close</CButton>
            </CModalFooter>
        </CModal>
    );
}
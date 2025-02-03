import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  CButton,
  CCard,
  CCardBody,
  CCardGroup,
  CCol,
  CContainer,
  CForm,
  CFormInput,
  CInputGroup,
  CInputGroupText,
  CRow,
} from '@coreui/react-pro';
import CIcon from '@coreui/icons-react';
import { cilLockLocked, cilUser } from '@coreui/icons';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../../../App'; // Adjust the path as necessary
import { AuthErrorModal } from 'src/components/ErrorModal';
import { error } from 'console';
import { FirebaseError } from '@firebase/app';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const navigate = useNavigate();

const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    console.log('Logging in...');
    try {
        await signInWithEmailAndPassword(auth, email, password);
        console.log('Logged in');
        navigate('/dashboard'); // Navigate to the dashboard on successful login
    } catch (error) {
        if (error instanceof FirebaseError) {
            // Handle Firebase auth errors
            switch (error.code) {
                case 'auth/invalid-email':
                    setErrorMessage('Invalid email address.');
                    break;
                case 'auth/user-disabled':
                    setErrorMessage('Client account is disabled.');
                    break;
                case 'auth/user-not-found':
                    setErrorMessage('Client not found.');
                    break;
                case 'auth/wrong-password':
                    setErrorMessage('Incorrect password.');
                    break;
                default:
                    setErrorMessage('An unknown error occurred.');
            }
        } else {
            // Handle other errors (e.g., network issues)
            setErrorMessage('An error occurred. Please try again.');
        }
        setShowErrorModal(true);
    }
};

  return (
    <div className="bg-body-tertiary min-vh-100 d-flex flex-row align-items-center">
      {showErrorModal && <AuthErrorModal message={errorMessage} showErrorModal={showErrorModal} setShowErrorModal={setShowErrorModal} />}
      <CContainer>
        <CRow className="justify-content-center">
          <CCol md={8}>
            <CCardGroup>
              <CCard className="p-5">
                <CCardBody>
                  <CForm onSubmit={handleLogin}>
                    <h1>Login</h1>
                    <p className="text-body-secondary">Sign In to your account</p>
                    <CInputGroup className="mb-3">
                      <CInputGroupText>
                        <CIcon icon={cilUser} />
                      </CInputGroupText>
                      <CFormInput
                        placeholder="Email"
                        autoComplete="username"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                      />
                    </CInputGroup>
                    <CInputGroup className="mb-4">
                      <CInputGroupText>
                        <CIcon icon={cilLockLocked} />
                      </CInputGroupText>
                      <CFormInput
                        type="password"
                        placeholder="Password"
                        autoComplete="current-password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                      />
                    </CInputGroup>
                    <CRow>
                        <CCol xs={6}>
                            <CButton type="submit" color="primary" className="px-4">
                            Login
                            </CButton>
                        </CCol>
                        <CCol xs={6} className="text-end">
                            <CButton color="link">
                            Forgot password?
                            </CButton>
                        </CCol>
                    </CRow>
                  </CForm>
                </CCardBody>
              </CCard>
              {/* <CCard className="text-white bg-primary py-5" style={{ width: '44%' }}>
                <CCardBody className="text-center">
                  <div>
                    <h2>Sign up</h2>
                    <Link to="/register">
                      <CButton color="primary" className="mt-3" active tabIndex={-1}>
                        Register Now!
                      </CButton>
                    </Link>
                  </div>
                </CCardBody>
              </CCard> */}
            </CCardGroup>
          </CCol>
        </CRow>
      </CContainer>
    </div>
  );
};

export default Login;
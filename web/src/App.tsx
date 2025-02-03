import React, { Suspense, useEffect } from 'react'
import { HashRouter, Navigate, Route, Routes } from 'react-router-dom'
import { useSelector } from 'react-redux'

import { CSpinner, useColorModes } from '@coreui/react-pro'

import './scss/style.scss'

// We use those styles to show code examples, you should remove them in your application.
import './scss/examples.scss'

import type { State } from './store'

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from 'firebase/auth'
import ProtectedRoute from './ProtectedRoute'
// import 'firebase/auth'
// import 'firebase/firestore'
// import {useAuthState} from 'react-firebase-hooks/auth'
// import {useCollectionData} from 'react-firebase-hooks/firestore'

const firebaseConfig = {

  apiKey: "AIzaSyAAzHGFJAMXNvdYfwbh8AA4lUY2F0sodIw",

  authDomain: "team-shaikh-app-52dc5.firebaseapp.com",

  projectId: "team-shaikh-app-52dc5",

  storageBucket: "team-shaikh-app-52dc5.appspot.com",

  messagingSenderId: "957281597606",

  appId: "1:957281597606:web:fd7925b8181c535118dc67",

  measurementId: "G-YLKP5N287Q"

};

// Initialize Firebase

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);

// Containers
const DefaultLayout = React.lazy(() => import('./layout/DefaultLayout'))

const Login = React.lazy(() => import('./views/pages/login/Login'))
const Register = React.lazy(() => import('./views/pages/register/Register'))
const Page404 = React.lazy(() => import('./views/pages/page404/Page404'))
const Page500 = React.lazy(() => import('./views/pages/page500/Page500'))


const App = () => {
  
  const { isColorModeSet, setColorMode } = useColorModes(
    'coreui-pro-react-admin-template-theme-default',
  )
  const storedTheme = useSelector((state: State) => state.theme)

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.href.split('?')[1])
    let theme = urlParams.get('theme')

    if (theme !== null && theme.match(/^[A-Za-z0-9\s]+/)) {
      theme = theme.match(/^[A-Za-z0-9\s]+/)![0]
    }

    if (theme) {
      setColorMode(theme)
    }

    if (isColorModeSet()) {
      return
    }

    setColorMode(storedTheme)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <HashRouter>
      <Suspense
        fallback={
          <div className="pt-3 text-center">
            <CSpinner color="primary" variant="grow" />
          </div>
        }
      >
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/404" element={<Page404 />} />
          <Route path="/500" element={<Page500 />} />
          <Route path="*" element={<ProtectedRoute><DefaultLayout /></ProtectedRoute>}/>
          {/* <Route path="*" element={<DefaultLayout />} /> */}
        </Routes>
      </Suspense>
    </HashRouter>
  )
}

export default App
export { app, analytics, auth} // firebase application instance


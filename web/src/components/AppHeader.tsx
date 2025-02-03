import { useEffect, useRef } from 'react'
import { NavLink } from 'react-router-dom'
import { useSelector, useDispatch } from 'react-redux'
import { useTranslation } from 'react-i18next'
import {
  CContainer,
//   CDropdown,
//   CDropdownItem,
//   CDropdownMenu,
//   CDropdownToggle,
  CHeader,
  CHeaderNav,
  CHeaderToggler,
  CNavLink,
  CNavItem,
  CButton,
//   useColorModes,
} from '@coreui/react-pro'
import CIcon from '@coreui/icons-react'
import {
//   cilContrast,
//   cilApplicationsSettings,
  cilMenu,
//   cilMoon,
//   cilSun,
//   cilLanguage,
//   cifGb,
//   cifEs,
//   cifPl,
} from '@coreui/icons'

import { AppBreadcrumb } from './index'

import {
  AppHeaderDropdown,
//   AppHeaderDropdownMssg,
  AppHeaderDropdownNotif,
//   AppHeaderDropdownTasks,
} from './header'

import type { State } from './../store'

import { auth } from '../App'

const AppHeader = () => {
  const headerRef = useRef<HTMLDivElement>(null)
//   const { colorMode, setColorMode } = useColorModes('coreui-pro-react-admin-template-theme-default')
  const { t } = useTranslation()

  const dispatch = useDispatch()
//   const asideShow = useSelector((state: State) => state.asideShow)
  const sidebarShow = useSelector((state: State) => state.sidebarShow)

  useEffect(() => {
    document.addEventListener('scroll', () => {
      headerRef.current &&
        headerRef.current.classList.toggle('shadow-sm', document.documentElement.scrollTop > 0)
    })
  }, [])

  return (
    <CHeader position="sticky" className="mb-4 p-0" ref={headerRef}>
        <CContainer className="border-bottom px-4" fluid>
            <CHeaderToggler
            onClick={() => dispatch({ type: 'set', sidebarShow: !sidebarShow })}
            style={{ marginInlineStart: '-14px' }}
            >
                <CIcon icon={cilMenu} size="lg" />
            </CHeaderToggler>
            <CHeaderNav className="d-none d-md-flex">
                <CNavItem>
                    <CNavLink to="/dashboard" as={NavLink}>
                    {t('dashboard')}
                    </CNavLink>
                </CNavItem>
                {/* <CNavItem>
                    <CNavLink href="#">{t('users')}</CNavLink>
                </CNavItem>
                <CNavItem>
                    <CNavLink href="#">{t('settings')}</CNavLink>
                </CNavItem> */}
            </CHeaderNav>
            <CHeaderNav className="d-none d-md-flex ms-auto">
                <AppHeaderDropdownNotif />
            </CHeaderNav>
            <CHeaderNav className="ms-auto ms-md-0">
                <li className="nav-item py-1">
                    <div className="vr h-100 mx-2 text-body text-opacity-75"></div>
                </li>
                {/* <CDropdown variant="nav-item" placement="bottom-end">
                    <CDropdownToggle caret={false}>
                    <CIcon icon={cilLanguage} size="lg" />
                    </CDropdownToggle>
                    <CDropdownMenu>
                    <CDropdownItem
                        active={i18n.language === 'en'}
                        className="d-flex align-items-center"
                        as="button"
                        onClick={() => i18n.changeLanguage('en')}
                    >
                        <CIcon className="me-2" icon={cifGb} size="lg" /> English
                    </CDropdownItem>
                    <CDropdownItem
                        active={i18n.language === 'es'}
                        className="d-flex align-items-center"
                        as="button"
                        onClick={() => i18n.changeLanguage('es')}
                    >
                        <CIcon className="me-2" icon={cifEs} size="lg" /> Español
                    </CDropdownItem>
                    <CDropdownItem
                        active={i18n.language === 'pl'}
                        className="d-flex align-items-center"
                        as="button"
                        onClick={() => i18n.changeLanguage('pl')}
                    >
                        <CIcon className="me-2" icon={cifPl} size="lg" /> Polski
                    </CDropdownItem>
                    </CDropdownMenu>
                </CDropdown>
                <CDropdown variant="nav-item" placement="bottom-end">
                    <CDropdownToggle caret={false}>
                    {colorMode === 'dark' ? (
                        <CIcon icon={cilMoon} size="lg" />
                    ) : colorMode === 'auto' ? (
                        <CIcon icon={cilContrast} size="lg" />
                    ) : (
                        <CIcon icon={cilSun} size="lg" />
                    )}
                    </CDropdownToggle>
                    <CDropdownMenu>
                    <CDropdownItem
                        active={colorMode === 'light'}
                        className="d-flex align-items-center"
                        as="button"
                        type="button"
                        onClick={() => setColorMode('light')}
                    >
                        <CIcon className="me-2" icon={cilSun} size="lg" /> {t('light')}
                    </CDropdownItem>
                    <CDropdownItem
                        active={colorMode === 'dark'}
                        className="d-flex align-items-center"
                        as="button"
                        type="button"
                        onClick={() => setColorMode('dark')}
                    >
                        <CIcon className="me-2" icon={cilMoon} size="lg" /> {t('dark')}
                    </CDropdownItem>
                    <CDropdownItem
                        active={colorMode === 'auto'}
                        className="d-flex align-items-center"
                        as="button"
                        type="button"
                        onClick={() => setColorMode('auto')}
                    >
                        <CIcon className="me-2" icon={cilContrast} size="lg" /> Auto
                    </CDropdownItem>
                    </CDropdownMenu>
                </CDropdown>
                <li className="nav-item py-1">
                    <div className="vr h-100 mx-2 text-body text-opacity-75"></div>
                </li> */}
                {/* <AppHeaderDropdown /> */}
                <CButton color='danger' variant='outline' size='sm' onClick={async () => await auth.signOut()}>Logout</CButton>
            </CHeaderNav>
            {/* <CHeaderToggler
            onClick={() => dispatch({ type: 'set', asideShow: !asideShow })}
            style={{ marginInlineEnd: '-12px' }}
            >
            <CIcon icon={cilApplicationsSettings} size="lg" />
            </CHeaderToggler> */}
        </CContainer>
        <CContainer className="px-4" fluid>
            <AppBreadcrumb />
        </CContainer>
    </CHeader>
  )
}

export default AppHeader

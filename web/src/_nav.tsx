import React, { ElementType } from 'react'
import CIcon from '@coreui/icons-react'
import {
  cilBell,
  cilCalculator,
  cilCalendar,
  cilChartPie,
  cilCursor,
  cilDrop,
  cilEnvelopeOpen,
  cilFile,
  cilFolderOpen,
  cilGrid,
  cilLayers,
  cilMap,
  cilNotes,
  cilPencil,
  cilPuzzle,
  cilSpeedometer,
  cilSpreadsheet,
  cilStar,
} from '@coreui/icons'
import { CNavGroup, CNavItem, CNavTitle } from '@coreui/react-pro'
import { Translation } from 'react-i18next'

export type Badge = {
  color: string
  text: string
}

export type NavItem = {
  badge?: Badge
  component: string | ElementType
  href?: string
  icon?: string | JSX.Element
  items?: NavItem[]
  name: string | JSX.Element
  to?: string
}

const _nav: NavItem[] = [
  {
    component: CNavItem,
    name: <Translation>{(t) => t('dashboard')}</Translation>,
    to: '/dashboard',
    icon: <CIcon icon={cilSpeedometer} customClassName="nav-icon" />,
    badge: {
      color: 'info-gradient',
      text: 'NEW',
    },
  },
  {
    component: CNavItem,
    name: "Activities",
    to: '/activities',
    icon: <CIcon icon={cilLayers} customClassName="nav-icon" />,
  },
  {
    component: CNavItem,
    name: "Statements",
    to: '/statements',
    icon: <CIcon icon={cilFolderOpen} customClassName="nav-icon" />,
  },
]

export default _nav

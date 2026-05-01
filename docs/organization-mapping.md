# Azure to GitHub mapping

## Azure governance structure
- Platform
  - Networking -> webIQ Infrastructure
  - Management -> webIQ Management
  - IAM -> webIQ Audit
  - nEXUS -> nEXUS
- Lifecycle
  - Development
  - Test
  - UAT
  - Staging
  - Production -> webIQ Production
- Customers
  - Commercial -> netIQ, GeneralDynamics, LockheedMartin, NorthropGrumman
  - Government -> Gi, DoD, USDA, DOC, DHS
- Corporate
  - Finance, HumanResources, IT, Marketing, Sales
- Decommissioned

## GitHub teams
- platform-admins
- networking
- identity-security
- audit-compliance
- commercial-customers
  - general-dynamics
  - lockheed-martin
  - northrop-grumman
- government-customers
  - dod

## Repository ownership
- platform-governance -> platform-admins, identity-security, audit-compliance
- platform-networking -> networking, platform-admins
- shared-bicep-modules -> platform-admins, networking, identity-security
- customer-commercial -> commercial-customers, platform-admins
- customer-government -> government-customers, identity-security, platform-admins

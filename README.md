# Transport Management Tool

## Description
In ABAP development teams, it's common for programmers to work concurrently on the same objects. This tool centralizes and facilitates tasks related to transport requests, such as creating transport of copies, comparing objects between environments, and collectively releasing request blocks. It allows for making informed decisions with accurate information.

## Installation

## Usage
The tool has an initial selection screen where programmers can enter the transport requests they want to move between systems.

It operates in two modes, Quality or Production, adapting options to the programmer's needs. The 'Compare Objects' option complements the displayed information.

**Use Case:**
Developer 1 is working on a development, storing changes in a transport request. Developer 2 is working on another development and needs to make changes to objects common to Developer 1. The tool facilitates this process.

Developer 1 initially uploads changes to the Quality system for testing. The tool visualizes the changes, allowing for detailed inspection.

The upper ALV displays a list of objects with the option to compare subcomponents. The lower ALV lists transport requests with collisions.

In Quality mode, the 'Create Transport of Copies' button creates a transport request with objects containing changes. Manual selection is also possible.

The tool allows for comparing objects and deciding which changes to include in transports.

When Developer 1 decides to upload changes to the production environment, the tool operates in Production mode, comparing against the production environment.

The main functionality in this mode is to display conflicts, allowing the programmer to decide which changes to take to production. The 'Reviewed' column visually indicates the reviewed status.

Once decisions are made, the 'Release' button releases all transport requests.

## Configuration
Configure the following variables in transaction STVARV:
- ZTRM_REQUEST_TARGET_DEV: System Identifier and Client for the Development system.
- ZTRM_REQUEST_TARGET_QUALITY: System Identifier and Client for the Quality system.
- ZTRM_RFC_PRODUCTIVE: Trusted RFC against the Productive system.
- ZTRM_RFC_QUALITY: Trusted RFC against the Quality system.

## Best Practices
To ensure proper functioning:
1. Add objects to the corresponding transportation request for development.
2. If an object is locked in a transportation order, delete tasks not making changes for the project and manually add objects to their transportation requests.
3. A transportation request should reference a single development or project.

## License

## Contribution

## Change History

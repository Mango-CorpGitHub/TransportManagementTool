![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/a74b3db5-4dbb-4b18-a958-799292b0e473)# Transport Management Tool

## Description
In ABAP development teams, it's common for programmers to work concurrently on the same objects. This tool centralizes and facilitates tasks related to transport requests, such as creating transport of copies, comparing objects between environments, and collectively releasing request blocks. It allows for making informed decisions with accurate information.

## Installation

## Usage
It has an initial selection screen where the transport requests that the programmer wants to move between systems can be entered.
![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/de2fc362-03cb-40ea-828c-93018e5104a1)

It can be stated that the program has two modes, depending on the system (Quality or Production) against which the transport is to be carried out. The information is presented in the same format in both modes; however, the options are adapted to what the programmer may need in each mode. The option to compare objects complements the information to be displayed.
Use case: Developer 1 is working on a development and stores the changes, both for existing objects and new ones, in a transport request. Developer 2 is working in parallel on another development and also needs to make some changes to objects common to Developer 1. To do this, Developer 2 creates their own transport request and enters the necessary entries for their changes.
Developer 1 needs to initially upload the changes from their development to the Quality system, with the purpose of verifying proper functionality with more test cases. They use the tool against the Quality system, specify their transport orders, and visualize the following:
The upper ALV corresponds to the list of all objects included in the orders entered in the selection screen. If the "Compare Objects" flag is selected, the subcomponents of each object will be displayed. That is, if the order has the entry R3TR CLAS, it will be shown broken down into its private, public, protected parts, methods, and local classes. It will also indicate if each component is new or has changes compared to the target system. The column that links each object to the lower part's ALV is the collision column. The Collision concept identifies if an object is present in more than one transport order. This allows warning that an object may have changes from another programmer and may need to discard those changes before transporting it to another environment. An object will be identified as having collisions with the Red icon in the "Has Collisions" column. If the icon in the column is green, it indicates that it has no collisions.
 ![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/7376437e-ff51-4715-aafa-712dc1f0ac80)

The lower ALV will correspond to the list of transport requests that have collisions with the objects from the transport entered on the selection screen.
The toolbar of the upper ALV provides common actions in both modes, but in Quality mode, the “Create Transport of Copies” button is particularly interesting. This button automatically creates a transport request (released if the user wishes) with objects containing changes compared to Quality. It is also possible to manually decide from the ALV which objects to include in the order, using the “Add to ToC” column.
Returning to the previously described use case, it can be observed that Developer 1 has two methods colliding with another transport order. They will have to decide whether to include those changes from Developer 2 in their transports. The tool also allows them to compare objects to identify changes in each object.
Once Developer 1 has decided to upload their changes to the production environment, they can rerun the tool in Production mode. This mode will again display the previously explained ALVs of objects and collisions, with the difference that it will compare them against the production environment.
![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/dd64ab05-9945-4246-8c5a-549f4e8c027e)
 
The main functionality in this mode will once again be to display conflicts, identifying which objects need to be reviewed. It will be the programmer's task to decide which changes will be taken to the production environment, and the tool will provide all the information needed to make that decision. Visually, the programmer can indicate what has been reviewed and what has not through the 'Reviewed' column.
Once the decision has been made on which changes will be uploaded to production, the 'Release' button can be used to release all the transport requests entered on the selection screen.


## Configuration
Configure the following variables in transaction STVARV:
- YTRM_REQUEST_TARGET_QUALITY: System Identifier and Client for the Quality system in format "SYS.CLI".
- YTRM_RFC_PRODUCTIVE: Trusted RFC against the Productive system with current user.
- YTRM_RFC_QUALITY: Trusted RFC against the Quality system with current user.

## Best Practices
For the proper functioning of the tool and to ensure that the provided information is accurate, it is necessary to follow a couple of best practices. Firstly, objects should be added to the corresponding transportation request for the development, regardless of whether they can be locked or not. Secondly, if an object is locked in a transportation order, any user making modifications will add a new task to that request. Users not making changes for the project identified in the request should delete these tasks and manually add the objects to their own transportation requests.
Following both best premises, it can be stated as follows: a transportation request should reference a single development or project. All objects contained in that request will correspond to changes related to that development or project.
Another best practice that facilitates code comparisons is to tag changes with an identifier for the referenced project, the user, and the date of the change. The identifier for the referenced project should be also in the Transport Request description.


## License

## Contribution

## Change History

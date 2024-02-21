**Developer A** is working on a development and stores the changes, both for existing objects and new ones, in a transport request. **Developer B** is working in parallel on another development and also needs to make some changes to objects common to **Developer A**. To do this, **Developer B** creates their own transport request and enters the necessary entries for their changes.

**Developer A** needs to initially upload the changes from their development to the Quality system, with the purpose of verifying proper functionality with more test cases.
For doing that **Developer A** excutes this Transport Management Tool. Selection screen will be as following:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/0011595c-3cae-45e9-a775-accd6111aec7)

It can be stated that the program has two modes, depending on the system (Quality or Production) against which the transport is to be carried out. The information is presented in the same format in both modes; however, the options are adapted to what the programmer may need in each mode. The check-box *"Compare Objects"* complements the information to be displayed.

**Developer A** should enter their transport request(s) in the select-option *"Request/Task"* and mark the Quality destination. To fully leverage the functionality of the tool, the *"Compare objects"* checkbox should also be checked. If *"Only my request"* box is checked, tool will verify if there is a Transport Request/Task among those entered whose owner is not the user who executes the program, useful for checking errors. Once executed, a screen similar to the following will be displayed:

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/633ef172-1c06-4bac-ad28-95a820989683)




The upper ALV corresponds to the list of all objects included in the orders entered in the selection screen. If the "Compare Objects" flag is selected, the subcomponents of each object will be displayed. That is, if the order has the entry R3TR CLAS, it will be shown broken down into its private, public, protected parts, methods, and local classes. It will also indicate if each component is new or has changes compared to the target system. The column that links each object to the lower part's ALV is the collision column. The Collision concept identifies if an object is present in more than one transport order. This allows warning that an object may have changes from another programmer and may need to discard those changes before transporting it to another environment. An object will be identified as having collisions with the Red icon in the "Has Collisions" column. If the icon in the column is green, it indicates that it has no collisions.

 ![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/7376437e-ff51-4715-aafa-712dc1f0ac80)

The lower ALV will correspond to the list of transport requests that have collisions with the objects from the transport entered on the selection screen.
The toolbar of the upper ALV provides common actions in both modes, but in Quality mode, the “Create Transport of Copies” button is particularly interesting. This button automatically creates a transport request (released if the user wishes) with objects containing changes compared to Quality. It is also possible to manually decide from the ALV which objects to include in the order, using the “Add to ToC” column.
Returning to the previously described use case, it can be observed that **Developer A** has two methods colliding with another transport order. They will have to decide whether to include those changes from **Developer B** in their transports. The tool also allows them to compare objects to identify changes in each object.
Once **Developer A** has decided to upload their changes to the production environment, they can rerun the tool in Production mode. This mode will again display the previously explained ALVs of objects and collisions, with the difference that it will compare them against the production environment.

![image](https://github.com/Mango-CorpGitHub/TransportManagementTool/assets/158566836/dd64ab05-9945-4246-8c5a-549f4e8c027e)
 
The main functionality in this mode will once again be to display conflicts, identifying which objects need to be reviewed. It will be the programmer's task to decide which changes will be taken to the production environment, and the tool will provide all the information needed to make that decision. Visually, the programmer can indicate what has been reviewed and what has not through the 'Reviewed' column.
Once the decision has been made on which changes will be uploaded to production, the 'Release' button can be used to release all the transport requests entered on the selection screen.

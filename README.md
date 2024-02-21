
## Description
In ABAP development teams, it's common for programmers to have to work concurrently on the same objects. Preparing a transport between environments involves special care for objects with code from multiple developers, excluding changes that haven't been approved for deployment. This tool is born with the purpose of centralizing and facilitating tasks related to transport requests: creating transport of copies, comparing objects between environments, collectively releasing request blocks, and more. Faced with complex tasks, it allows for making the best decisions with the most accurate information. It's a tool made by ABAPers for ABAPers.
## Installation
Install this project via [ABAPGit](https://abapgit.org/). 

## Configuration
Configure the following variables in transaction `STVARV`:
- **YTRM_REQUEST_TARGET_QUALITY**: System Identifier and Client for the Quality system in format "SYS.CLI".
- **YTRM_RFC_PRODUCTIVE**: Trusted RFC name against the Production system with current user logon.
- **YTRM_RFC_QUALITY**: Trusted RFC name against the Quality system with current user logon.
  An example of RFC configuration:
  
## Usage
Learn full potential of this tool with a real example in our [Usage Guide](usage.md).


## Best Practices
For the proper functioning of the tool and to ensure that the provided information is accurate, it is necessary to follow a couple of best practices. 
Firstly, objects should be added to the corresponding transportation request for the development, regardless of whether they can be locked or not. Secondly, if an object is locked in a transportation order, any user making modifications will add a new task to that request. Users not making changes for the project identified in the request should delete these tasks and manually add the objects to their own transportation requests.
Following both best premises, it can be stated as follows: a transportation request should reference a single development or project. All objects contained in that request will correspond to changes related to that development or project.
Another best practice that facilitates code comparisons is to tag changes with an identifier for the referenced project, the user, and the date of the change. The identifier for the referenced project should be also in the Transport Request description.

## License
Terms & Conditions set out in the [LICENSE file](LICENSE).

## Contribution

## Change History

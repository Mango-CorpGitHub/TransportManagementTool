
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
Follow the provided [methodology](best_practices.md) to achieve optimal tool performance and maintain a coordinated team in all matters related to the transport of objects.

## License
Terms & Conditions set out in the [LICENSE file](LICENSE).

## Contribution

## Change History

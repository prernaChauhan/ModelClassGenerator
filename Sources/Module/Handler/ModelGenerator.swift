import Kitura
import LoggerAPI
import SwiftyJSON
import Foundation




var classNamesUsed = [String : Bool]()
var initString = "\tinit(jsonDict: Dictionary<String, AnyObject>) { \n"
var fileName: String = ""

/**
 Gets name of model class to be created.
 
 - parameter type:  Class Name for array or dictionary.
 - parameter parent:    ----------------------------
 
 - returns: The class Name entered by user
 */

func getModelName(type: String, parent: String) -> String {
    print("Enter class name for " + type + " " + parent)
    var classname: String?
    while (true) {
        classname = readLine()
        if classname!.characters.count > 0 {
            break
        }
    }
    return classname!
}


/**
 Checks if name of the class entered by user is already used or not
 
 - parameter className:  Name of the class entered by user.
 
 - returns: True if className is already used, false otherwise.
 */

func isClassNameUsed(className: String) -> Bool {
    if classNamesUsed[className] != nil {
        return true
    }
    return false
}


/**
 Handler for request
 
 - parameter request:  Name of the class entered by user.
 - parameter response: ------------
 - parameter next: ---------
  */

func handleRequestForModelCreation(request: RouterRequest, response: RouterResponse, next: ()->Void) -> Void {
    Log.info("Handling /post")
    guard let parsedBody = request.body else {
        next()
        return
    }
    classNamesUsed.removeAll()
    
    switch(parsedBody) {
    case .json(let jsonBody):
        let className = getModelName(type: "Model Class", parent: "")
        fileName = className + ".swift"
        var arrayElements = [String : Int]()
        var initializedData = [String : Int]()
        makeModelClassFromJsonObject(dict: jsonBody, className: className, arrayElements: &arrayElements, initializedData: &initializedData, flag: true)
        response.status(.OK)
    default:
        break
    }
    next()
}

/**
 Initializes array elements.
 
 - parameter array: Array for which elements needs to be initialized.Array
 - parameter name: Variable name storing array elements
 
 - returns: String containing initialized array elements.
 */

func initializeArrayElements(array: JSON, name: String) -> String {
    var result: String = "\t\tif let " + name + " = jsonDict[\"" + name + "\"] as? "
    for (_,value) in array {
        switch(value.type) {
        case .string :
            result = result + "[String] { \n"
            result = result + "\t\t\tfor value in " + name + " { \n"
            result = result + "\t\t\t\t self." + name + ".append(value) \n\t\t\t}\n"
        case .bool :
            result = result + "[Bool] { \n"
            result = result + "\t\t\tfor value in " + name + " { \n"
            result = result + "\t\t\t\t self." + name + ".append(value) \n\t\t\t}\n"
        case .number :
            result = result + "[Number] {\n"
            result = result + "\t\t\tfor value in " + name + " { \n"
            result = result + "\t\t\t\t self." + name + ".append(value) \n \t\t\t}\n"
        case .dictionary :
            result = result + "[Dictionary<String, AnyObject>] {\n"
            result = result + "\t\t\tfor value in " + name + " {\n"
            result = result + "\t\t\t\t let data = " + name + ".init(jsonDict: value) \n"
            result = result + "\t\t\t\t\t self." + name + ".append(data) \n\t\t\t}\n"
        case .array :
            result = result + "[AnyObject] {\n"
            result = result + "\t\t\t self." + name + " = " + name + "\n\t\t\t}\n"
        default:
            break
        }
        break
    }
    return result
}

func writeToFile(fileName: String, text: String) {

    var data = text.data(using: String.Encoding.utf8, allowLossyConversion: true)!

    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let path = dir.appendingPathComponent("/SwiftModelClasses/" + fileName)

        if FileManager.default.fileExists(atPath: path.path) {
            do {
                let fileHandle = try FileHandle(forWritingTo: path)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
            catch {
                
            }
            
            }
            else {
                print ("Can't open fileHandle")
            //writing
                do {
                    try data.write(to: path, options: .atomic)
                }
                
            catch {/* error handling here */}
            }
        }
/*
        
        //writing
        do {
            try text.write(to: path, atomically: false, encoding: String.Encoding.utf8)
        }
            
        catch {/* error handling here */} */

 }


/**
 Creates string for variable declaration
 
 - parameter type:  Type of parameter defined.
 - parameter name: Name of the variable.
 
 -returns: String for variable declaration
 */

func getVaribleDeclaration(name: String, type: String) -> String {
    return "\tvar " + name + ": " + type + "\n"
}

/**
 Creates string for variable initialization
 
 - parameter type:  Type of parameter defined.
 - parameter name: Name of the variable.
 
 -returns: String for variable initialization
 */

func getVaribleInitialization(name: String, type: String) -> String {
    if(type == "String" || type == "Number" || type == "Bool") {
        return "\t\tself." + name + " = jsonDict[\"" + name + "\"] as? " + type + "\n" }
    else {
        var result = "\t\t if let data = jsonDict[\"" + name + "\"] as? Dictionary<String, AnyObject> {\n "
        result = result + "\t\t\t self." + name + " = " + name + ".init(jsonDict: data) \n\t\t}\n"
        return result
    }
}


/**
 Creates class from JsonObject
 
 - parameter dict:  JsonObject for which model class is to be created.
 - parameter className: Name of the Model class.
 - parameter arrayElements: Dictionary of string generated from all keys present in an array of dictionary.
 - parameter initializedData: Dictionary of string generated for init method in model classes.
 - parameter flag: To notify if model class needs to be created or not
 */

func makeModelClassFromJsonObject(dict: JSON , className : String,  arrayElements: inout [String : Int], initializedData: inout [String : Int], flag: Bool) {
    var resultString: String = ""
    var initializedStringData: String = ""
    
    if (flag) {
        classNamesUsed[className] = true
        resultString =  "class " + className + " {\n"
    }
    
    for (key, value) in dict {
        var val = ""
        var initCalls: String = ""
        
        switch (value.type) {
        case .string :
            val = getVaribleDeclaration(name: key, type: "String")
            initCalls = initCalls + getVaribleInitialization(name: key, type: "String")
        case .bool :
            val = getVaribleDeclaration(name: key, type: "Bool")
            initCalls = initCalls + getVaribleInitialization(name: key, type: "Bool")
        case .number :
            val = getVaribleDeclaration(name: key, type: "Number")
            initCalls = initCalls + getVaribleInitialization(name: key, type: "Number")
        case .dictionary :
            if (!isClassNameUsed(className: key)) {
                makeModelClassFromJsonObject(dict: dict[key], className: key, arrayElements: &arrayElements, initializedData : &initializedData, flag: true)
                val = getVaribleDeclaration(name: key, type: key)
                initCalls = initCalls + getVaribleInitialization(name: key, type: key)
            }
            else {
                val = getVaribleDeclaration(name: key, type: key)
                initCalls = initCalls + getVaribleInitialization(name: key, type: key)

            }
        case .array :
            if (!isClassNameUsed(className: key)) {
                val = "\tvar " + key + createModelObjectFromArray(array: dict[key], className: key) + "\n"
                initCalls = initCalls + initializeArrayElements(array: dict[key] , name: key)
                initCalls = initCalls + "\t\t}\n"
            }
            else {
                val = "\t var " + key + ": [" + key + "] \n"
                initCalls = initCalls + initializeArrayElements(array: dict[key] , name: key)
                initCalls = initCalls + "\t\t}\n"
            }
        default:
            break
        }
        
        //------To be done only if dictionary element is present in an array
        if(!flag) {
            arrayElements[val] = 1
            initializedData[initCalls] = 1
        }
        
        resultString = resultString + val
        initializedStringData = initializedStringData + initCalls
    }
    
    if(flag) {
        resultString = resultString + initString + initializedStringData + "\t}\n" + "} \n"
        writeToFile(fileName: fileName, text: resultString)
    }
    
}


/**
 Creates class for an array of dictionary
 
 - parameter className: Name of the Model class.
 - parameter arrayElements: Dictionary of string generated from all keys present in an array of dictionary.
 - parameter initializedData: Dictionary of string generated for init method in model classes.
 */

func createClassForArrayOfDictionary(classname: String, arrayElements: [String : Int], initializedData : [String : Int]) {
    classNamesUsed[classname] = true
    var resultString = "class " + classname + "{\n"
    for (key,_) in arrayElements {
        resultString = resultString + key
    }
    resultString = resultString + initString
    for (key,_) in initializedData {
        resultString = resultString + key
    }
    resultString = resultString + "\t}\n } \n"
    writeToFile(fileName: fileName, text: resultString)
}

/**
 Handles model creation for array objects
 
 - parameter dict:  Array Object for which model class is to be created.
 - parameter className: Name of the Model class.
 
 - returns: String for variable declaration of an array object
 */

func createModelObjectFromArray(array: JSON, className: String) -> String {
   // classNamesUsed[className] = true
    var arrayVariableDeclaration: String = ""
    var isFirstElement = true
    var flag: Bool = false
    var arrayElements: [String : Int] = [:]
    var initializedData: [String : Int] = [:]
    var arrayElementCount = 1
    
    for (_,value) in array {
        switch (value.type) {
        case .string :
            arrayVariableDeclaration = arrayVariableDeclaration + ": [String]"
            flag = true
        case .bool :
            arrayVariableDeclaration = arrayVariableDeclaration + ": [Bool]"
            flag = true
        case .number :
            arrayVariableDeclaration = arrayVariableDeclaration + ": [Number]"
            flag = true
        case .dictionary :
            if (isFirstElement) {
                arrayVariableDeclaration = arrayVariableDeclaration + ": [" + className + "]"
                isFirstElement = false
            }
            makeModelClassFromJsonObject(dict: value, className: "", arrayElements: &arrayElements, initializedData: &initializedData, flag: false)
        case .array :
                if(arrayElementCount == 1) {
                    arrayVariableDeclaration = arrayVariableDeclaration + ": [AnyObject]"
                    arrayElementCount = arrayElementCount + 1
                }
                flag = true
        default:
            break
        }
        if(flag) {
            break
        }
    }

    if(!flag && classNamesUsed[className] == nil) {
        createClassForArrayOfDictionary(classname: className, arrayElements: arrayElements, initializedData: initializedData)
    }
    arrayElements.removeAll()
    initializedData.removeAll()
    return arrayVariableDeclaration
}

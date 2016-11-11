import Kitura
import HeliumLogger
import SwiftyJSON


HeliumLogger.use()

public let router = Router()

router.all("/*", middleware: BodyParser())

router.post("/post", handler: handleRequestForModelCreation)



Kitura.addHTTPServer(onPort: 9000, with: router)
Kitura.run()

//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport
import Alamofire
import PromisedFuture
import SwiftyJSON
import SwiftSVG
import Foundation

// MARK: - Welcome
struct Welcome: Codable {
    let user: User
    let error: JSONNull?
}

// MARK: - User
struct User: Codable {
    let subscribe: Bool
    let district: District
    let id: Int
    let name, username, surname: String
    let roles: [String]
    let email: String
}

// MARK: - District


// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

struct K {
    struct ProductionServer {
        //static let baseURL = "https://api.medium.com/v1"
        //static let baseURL = "http://10.0.1.3:8181/"
        static let baseURL = "https://vmeste.srvdev24.ru:9090/"
    }

    struct APIParameterKey {
        static let username = "_username"
        static let password = "_password"
    }

//    struct LoginParameterKey {
//        static let password = "password"
//        static let username = "username"
//    }
    struct RegistrationParameterKey {
        static let username      = "username" // send email in this field
        static let surname       = "surname"
        static let name          = "name"
        static let email         = "email"
        static let plainPassword = "plainPassword"
        static let districtId    = "districtId"
    }

    struct APIPlainPassword {
        static let first = "first"
        static let second = "second"
    }
}

enum HTTPHeaderField: String {
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case XMLHttpRequest = "X-Requested-With"
}

enum ContentType: String {
    case json = "application/json"
    case XMLHttpRequest = "XMLHttpRequest"
}

protocol APIConfiguration: URLRequestConvertible {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters? { get }
}

extension APIConfiguration {
    // MARK: - URLRequestConvertible
//    func asURLRequest() throws -> URLRequest {
//        let url = try K.ProductionServer.baseURL.asURL()
//
//        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
//
//        // HTTP Method
//        urlRequest.httpMethod = method.rawValue
//
//        // Common Headers
//        //urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
//        urlRequest.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
//        //        let headers: HTTPHeaders = [
//        //            "X-Requested-With": "XMLHttpRequest"
//        //        ]
//
//        // Parameters
//
//        if let parameters = parameters {
//            do {
//                print(#line, parameters)
//                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
//                print(#line, "\(parameters)")
//            } catch {
//                print(#line, "\(error.localizedDescription)")
//                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
//            }
//        }
//
//        return urlRequest
//    }

    func asURLRequest() throws -> URLRequest {
        let url = try K.ProductionServer.baseURL.asURL()

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))

        // HTTP Method
        urlRequest.httpMethod = method.rawValue

        // Common Headers
        urlRequest.setValue(ContentType.XMLHttpRequest.rawValue, forHTTPHeaderField: HTTPHeaderField.XMLHttpRequest.rawValue)

        print(#line, parameters!)

        do {
            urlRequest = try URLEncoding.httpBody.encode(urlRequest, with: parameters!)
            return urlRequest
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
    }
}

enum UserEndpoint: APIConfiguration {

    case login(username: String, password: String)
    case getUser
    case district
    case registration(
        username: String,
        surname: String,
        name: String,
        email: String,
        plainPassword: [String: Any],
        districtId: Int
    )

    // MARK: - HTTPMethod
    var method: HTTPMethod {
        switch self {
        case .login, .registration:
            return .post
        case .getUser, .district:
            return .get
        }
    }

    // MARK: - Path
    var path: String {
        switch self {
        case .login:
            return  "login_check" // return "api/v1/login"
        case .getUser:
            return "api/user"
        case .district:
            return "api/district/list"
        case .registration:
            return "api/registration"
        }
    }

    // MARK: - Parameters
    var parameters: Parameters? {
        switch self {
        case .login(let username, let password):
            return [
                K.APIParameterKey.username: username,
                K.APIParameterKey.password: password
            ]
        case .registration(
            let username,
            let surname,
            let name,
            let email,
            let plainPassword,
            let districtId
        ):
            return [
                K.RegistrationParameterKey.username: username,
                K.RegistrationParameterKey.surname: surname,
                K.RegistrationParameterKey.name: name,
                K.RegistrationParameterKey.email: email,
                K.RegistrationParameterKey.plainPassword: plainPassword as [String: Any],
                K.RegistrationParameterKey.districtId: districtId,
            ]
        case .getUser, .district:
            return nil
        }
    }
}


struct UserResponse: Codable {
    var success: Bool
}

struct District: Codable {
    let id: Int
    let name, center, svg: String
}

struct RegistrationData: Codable {
    var username: String // send email in this field
    var surname: String
    var name: String
    var email: String
    var plainPassword: PlainPasswordData
    var districtId: Int

    var dic: [String: Any] {
        get {
            return [
                "username": username,
                "surname": surname,
                "name": name,
                "email": email,
                "plainPassword": plainPassword.dic,
                "districtId": districtId
            ]
        }
    }
}

struct PlainPasswordData: Codable {
    var first: String
    var second: String

    var dic: [String: Any] {
        get {
            return ["first": first, "second": second]
        }
    }
}

struct RegistrationResponse: Codable {
    let result: Bool
    let errors: Errors?
}

// MARK: - Errors
struct Errors: Codable {
    let the0: String
    let email, username: [String]
    let plainPassword: PlainPasswordResponse
    let districtID: [String]

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case email, username, plainPassword
        case districtID = "districtId"
    }
}

// MARK: - PlainPassword
struct PlainPasswordResponse: Codable {
    let first: [String]
}

class APIClient {
    @discardableResult
    public static func performRequest<D: Decodable, R: APIConfiguration>(route: R, decoder: JSONDecoder = JSONDecoder()) -> Future<D> {
        return Future(operation: { completion in

            AF.request(route).responseDecodable(decoder: decoder, completionHandler: { (response: AFDataResponse<D>) in
                switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        })
    }

    static func login(username: String, password: String) -> Future<UserResponse> {
        return performRequest(route: UserEndpoint.login(username: username, password: password))
    }

    static func getUser() -> Future<Welcome> {
        return performRequest(route: UserEndpoint.getUser)
    }

    static func districtList() -> Future<[District]> {
        return performRequest(route: UserEndpoint.district)
    }

    static func registration(
        username: String,
        surname: String,
        name: String,
        email: String,
        plainPassword: PlainPasswordData,
        districtId: Int
        ) -> Future<RegistrationResponse> {
        return performRequest(route: UserEndpoint.registration(username: username, surname: surname, name: name, email: email, plainPassword: plainPassword.dic, districtId: districtId))
    }

}

class MyViewController : UIViewController {
    var dl = [District]()
    let label = UILabel()
    override func loadView() {
        let view = UIView()
        
        view.backgroundColor = .white

        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view

        login()
    }

    func login() {

        let parameters: Parameters = [
            "_username": "ilaytest",
            "_password": "1234567"
        ]
        let headers: HTTPHeaders = [
            "X-Requested-With": "XMLHttpRequest"
        ]

        let url = "https://vmeste.srvdev24.ru:9090/login_check"
        let urlUser = "https://vmeste.srvdev24.ru:9090/api/user"
        let urlDistrictList = "https://vmeste.srvdev24.ru:9090/api/district/list"
        let urlRegistration = "https://vmeste.srvdev24.ru:9090/api/registration"
        var userStatusURL = "https://vmeste.srvdev24.ru:9090/api/lk/statistic/"

        var cookies = Session.default.session.configuration.httpCookieStorage?.cookies(for: URL(string: url)!)
        //AF.SessionManager.default.session.configuration.httpCookieStorage.cookies(for: url)

        APIClient.login(username: "alifspb@yandex.ru", password: "blu3@T0p").execute(onSuccess: { response in
            print(#line, "\(response)")

        }) { error in
            print(#line, "\(error)")
        }



//        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseJSON { response in
//            print("\(response)")
//            if let headerFields = response.response?.allHeaderFields as? [String: String], let URL = response.request?.url
//            {
//                 let cookies2 = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
//                 print(cookies2)
//                cookies = cookies2
//            }
//        }
//
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            AF.request(urlUser, method: .get, headers: headers).responseJSON { res in
                print(#line, "user: \(JSON(res.value))")

                let json = JSON(res.value!)
                let id = json["user"]["id"].stringValue
                userStatusURL.append(id)

                print(#line, userStatusURL)
                DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                    AF.request(userStatusURL, method: .get, headers: headers).responseJSON { res in
                        print(#line, "user status: \(JSON(res.value))")
                    }
                }

            }
        }

//        APIClient.getUser().execute(onSuccess: { response in
//            print("\(response)")
//        }) { error in
//            print("\(error)")
//        }


//        let paremeterPlainPassword = PlainPasswordData(first: "password", second: "password")
//        let paremetersRegistration = RegistrationData(username: "alifspb6@yandex.ru", surname: "alif6", name: "alif6", email: "alifspb6@yandex.ru", plainPassword: paremeterPlainPassword, districtId: 3)

        //print(#line, paremetersRegistration.dic)
//        AF.request(urlRegistration, method: .post, parameters: paremetersRegistration.dic, encoding: URLEncoding.httpBody, headers: headers).responseJSON { response in
//
//            if let headerFields = response.response?.allHeaderFields as? [String: String],
//               let URL = response.request?.url {
//
//                let cookiesResponse = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
//
//
//                print(#line, cookiesResponse as Any)
//            }
//
//
//            print(#line, "\(JSON(response.value))")
//        }

//                DispatchQueue.main.asyncAfter(deadline: .now()+5) {

//                    APIClient.districtList().execute(onSuccess: { response in
//                        print(#line, "\(response)")
//                        self.dl = response
//
//                        for name in response {
//                            self.label.text = name.name
//                        }
//                    }) { error in
//                        print(#line, "\(error)")
//                    }

//                    AF.request(urlDistrictList, method: .get, headers: headers).responseJSON(completionHandler: { response in
//                        print(#line, "\(response)")
//                    })
//                }

        ////            AF.request(urlDistrictList, method: .get, headers: headers).responseJSON(completionHandler: { response in
        ////                print(#line, "\(response)")
        ////            })

//        APIClient.registration(username: "alifspb2@yandex.ru", surname: "alif2", name: "alif2", email: "alifspb3@yandex.ru", plainPassword: paremeterPlainPassword, districtId: 3).execute(onSuccess: { response in
//            print(#line, "\(response)")
//        }) { error in
//            print(#line, "\(error)")
//        }

//        APIClient.getUser().execute(onSuccess: { response in
//            print("\(response)")
//        }) { error in
//            print("\(error)")
//        }
    }

}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()

//    {
//        "result" : false,
//        "errors" : {
//            "plainPassword" : {
//                "first" : [
//                "Введенные пароли не совпадают."
//                ]
//            }
//        }
//}

//{
//    "result" : true,
//    "errors" : null
//}

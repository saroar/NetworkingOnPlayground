//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport
import Alamofire
import PromisedFuture

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
}

protocol APIConfiguration: URLRequestConvertible {
    var method: HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters? { get }
}

extension APIConfiguration {
    // MARK: - URLRequestConvertible
    func asURLRequest() throws -> URLRequest {
        let url = try K.ProductionServer.baseURL.asURL()

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))

        // HTTP Method
        urlRequest.httpMethod = method.rawValue

        // Common Headers
//        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
//        urlRequest.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
//        urlRequest.setValue(
//            ContentType.json.rawValue,
//            forHTTPHeaderField: HTTPHeaderField.XMLHttpRequest.rawValue
//        )
        urlRequest.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        //        let headers: HTTPHeaders = [
        //            "X-Requested-With": "XMLHttpRequest"
        //        ]

        // Parameters
        if let parameters = parameters {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                
            } catch {
                throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
            }
        }

        return urlRequest
    }
}

enum UserEndpoint: APIConfiguration {

    case login(username: String, password: String)

    case profile(id: Int)

    // MARK: - HTTPMethod
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .profile:
            return .get
        }
    }

    // MARK: - Path
    var path: String {
        switch self {
        case .login:
            return  "login_check" // return "api/v1/login"
        case .profile(let id):
            return "profile/\(id)"
        }
    }

    // MARK: - Parameters
    var parameters: Parameters? {
        switch self {
        case .login(let username, let password):
            return [K.APIParameterKey.username: username, K.APIParameterKey.password: password]
        case .profile:
            return nil
        }
    }
}

struct UserResponse: Codable {
    var success: Bool
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
}

class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view

        login()
    }

    func login() {
        APIClient.login(username: "ilaytest", password: "1234567").execute(onSuccess: { userRes in
            print("\(userRes)")
        }) { error in
            print("\(error)")
        }

//        let url = "https://vmeste.srvdev24.ru:9090/login_check"
//        let parameters: Parameters = [
//            "_username": "ilaytest",
//            "_password": "1234567"
//        ]
//        let headers: HTTPHeaders = [
//            "X-Requested-With": "XMLHttpRequest"
//        ]
//
//        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers).responseJSON { res in
//            print("\(res)")
//        }
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()

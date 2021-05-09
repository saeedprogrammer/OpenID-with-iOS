//
//  ViewController.swift
//  IdentityAppDemo
//
//  Created by Saeed on 4/27/21.
//

import UIKit
import AppAuth


struct AuthConstants{
   
    
    private(set) static var issuer: String = "https://demo.identityserver.io/"
    private(set) static var  auhtClientId: String = "interactive.public"
    private(set) static var  redirectUri: String = "io.identityserver.demo:/oauthredirect"
    
    private(set) static var appAuthExampleAuthStateKey: String = "authState";

    
}
class ViewController: UIViewController{
    
    @IBOutlet weak var token_value_lbl: UILabel!
    @IBOutlet weak var user_info_lbl: UILabel!
    private var authState: OIDAuthState?
   
      
        
        func getAuthToken(viewController: UIViewController) {
            guard let issuer = URL(string: AuthConstants.issuer) else {
                print("Error creating URL for : \(AuthConstants.issuer)")
                return
            }
            
            print("Fetching configuration for issuer: \(issuer)")
            
            // discovers endpoints
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
                guard let config = configuration else {
                    print("Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                    return
                }
                
                print("Got configuration: \(config)")
              
                self.doAuthWithAutoCodeExchange(configuration: config, clientID: AuthConstants.auhtClientId, clientSecret: nil, controller: viewController, completed:{
                    (msg , access_token , id_token)  in
                    self.token_value_lbl.text = access_token
                })
            }
            
        }
    
    @IBAction func getAuthClickAction(_ sender: Any) {
        getAuthToken(viewController: self)
   
    }
    @IBAction func getUserInfoClickAction(_ sender: Any) {
        getUserInfo()
   
    }
    
    func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?, controller: UIViewController ,  completed:@escaping(String?,String,String)->Void) {
           
           guard let redirectURI = URL(string: AuthConstants.redirectUri) else {
               print("Error creating URL for : \(AuthConstants.redirectUri)")
               return
           }
           
        
           
           // builds authentication request
           let request = OIDAuthorizationRequest(configuration: configuration,
                                                 clientId: clientID,
                                                 clientSecret: clientSecret,
                                                 scopes: ["openid", "profile" , "email" ],
                                                 redirectURL: redirectURI,
                                                 responseType: OIDResponseTypeCode,
                                                 additionalParameters: nil)
           
           // performs authentication request
           print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        let sceneDelegate = self.view.window!.windowScene!.delegate as! SceneDelegate
     
        sceneDelegate.currentAuthorizationFlow  = OIDAuthState.authState(byPresenting: request, presenting: controller) {
               authState, error in
               if let authState = authState {
                   self.setAuthState(authState)
                   print("Got authorization tokens. Access token: \(authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN")")
                completed(nil,authState.lastTokenResponse?.accessToken ?? "" , authState.lastTokenResponse?.idToken ?? "" )
                   
            
             
               } else {
                self.setAuthState(nil)
                   print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                    completed(error?.localizedDescription ?? "DEFAULT_ERROR", "" ,  "" )
               }
           }
     
            
       }
    
    func setAuthState(_ authState: OIDAuthState?) {
          if (self.authState == authState) {
              return;
          }
          self.authState = authState;
          self.authState?.stateChangeDelegate = self;
       //   self.stateChanged()
      }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    func getUserInfo()
    {
        self.authState?.performAction(freshTokens: {
            accessToken, idToken, error in
            if error != nil  {
              print("Error fetching fresh tokens: \(error?.localizedDescription ?? "Unknown error")")
              return
            }
            guard let accessToken = accessToken else {
              return
            }

            

            let userInfo = self.authState?.lastAuthorizationResponse.request.configuration.discoveryDocument?.userinfoEndpoint
            let url = userInfo //change the url
             let session = URLSession.shared
            var request = URLRequest(url: url!)
            request.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
             let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in

                 guard error == nil else {
                     return
                 }

                 guard let data = data else {
                     return
                 }

                do {
                   //create json object from data
                   if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                      print(json)
                    DispatchQueue.main.async
                    {
                        self.user_info_lbl.text = json.description
                    }
                   
                   }
                } catch let error {
                  print(error.localizedDescription)
                    self.user_info_lbl.text = error.localizedDescription
                }
             })

             task.resume()
        })
    }
}

extension ViewController : OIDAuthStateChangeDelegate {

    func didChange(_ state: OIDAuthState) {
        
        print("didChange")
       }

       func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
          
        print("authState")
       }
}

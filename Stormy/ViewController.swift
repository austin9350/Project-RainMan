//
//  ViewController.swift
//  Stormy
//  Created by Aaron A

import UIKit
import AVFoundation
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
    let swipeRec = UISwipeGestureRecognizer()
    
    //Current Weather outlets
    @IBOutlet weak var windBag: UIImageView!
    @IBOutlet weak var umbrella: UIImageView!
    @IBOutlet weak var rainDrop: UIImageView!
    @IBOutlet weak var userLocationLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    //@IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    //@IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var degreeButton: UIButton!
    @IBOutlet weak var swipeView: UIView!
    @IBOutlet weak var heatIndex: UIImageView!
    @IBOutlet weak var dayZeroTemperatureLowLabel: UILabel!
    @IBOutlet weak var dayZeroTemperatureHighLabel: UILabel!
    
    @IBOutlet weak var windUILabel: UILabel!
    @IBOutlet weak var rainUILabel: UILabel!
    @IBOutlet weak var humidityUILabel: UILabel!
    
    
    //Daily Weather outlets
    @IBOutlet weak var dayZeroTemperatureLow: UILabel!
    @IBOutlet weak var dayZeroTemperatureHigh: UILabel!
    
    @IBOutlet weak var dayOneWeekDayLabel: UILabel!
    @IBOutlet weak var dayOneHighLow: UILabel!
    @IBOutlet weak var dayOneImage: UIImageView!
    
    @IBOutlet weak var dayTwoWeekDayLabel: UILabel!
    @IBOutlet weak var dayTwoHighLow: UILabel!
    @IBOutlet weak var dayTwoImage: UIImageView!
    
    @IBOutlet weak var dayThreeWeekDayLabel: UILabel!
    @IBOutlet weak var dayThreeHighLow: UILabel!
    @IBOutlet weak var dayThreeImage: UIImageView!
    
    @IBOutlet weak var dayFourWeekDayLabel: UILabel!
    @IBOutlet weak var dayFourHighLow: UILabel!
    @IBOutlet weak var dayFourImage: UIImageView!
    
    @IBOutlet weak var dayFiveWeekDayLabel: UILabel!
    @IBOutlet weak var dayFiveHighLow: UILabel!
    @IBOutlet weak var dayFiveImage: UIImageView!
    
    @IBOutlet weak var daySixWeekDayLabel: UILabel!
    @IBOutlet weak var daySixHighLow: UILabel!
    @IBOutlet weak var daySixImage: UIImageView!
    
    //Alerts
    
    @IBOutlet weak var wAlerts: UILabel!
    
    
    var seenError : Bool = false
    var locationFixAchieved : Bool = false
    var locationStatus : NSString = "Not Started"
    var locationManager: CLLocationManager!
    var userLocation : String!
    var userLatitude : Double!
    var userLongitude : Double!
	  var userTemperatureCelsius : Bool!
  
    private let apiKey = "YOUR API KEY"  // https://developer.forecast.io
  
    var audioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
      
        // Get user preference
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        userTemperatureCelsius = defaults.boolForKey("celsius")
	      print("defaults: celsius  = \(userTemperatureCelsius)");
      
        swipeRec.addTarget(self, action: "swipedView")
        swipeRec.direction = UISwipeGestureRecognizerDirection.Down
        swipeView.addGestureRecognizer(swipeRec)
        
        refresh()
        
        //PushNotifications
        
    }
    
    
    func swipedView(){
        
        self.swooshsound()
        refresh()
        
    }
    
    //LOCATION LOCATION LOCATION
    
    func initLocationManager() {
        seenError = false
        locationFixAchieved = false
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locationManager.stopUpdatingLocation()
        if (seenError == false) {
            seenError = true
            print(error, appendNewline: false)
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        
        guard let location = manager.location else {
            return
        }
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error)->Void in
            
            guard let pm = placemarks?.first else {
                return
            }
            
            self.displayLocationInfo(pm)
        })
        
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            let locationArray = locations as NSArray
            let locationObj = locationArray.lastObject as! CLLocation
            let coord = locationObj.coordinate
            self.userLatitude = coord.latitude
            self.userLongitude = coord.longitude
            
            getCurrentWeatherData()
        }
    }
    
    func displayLocationInfo(placemark: CLPlacemark?) {
        if let containsPlacemark = placemark {
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
//            let postalCode = (containsPlacemark.postalCode != nil) ? containsPlacemark.postalCode : ""
            let administrativeArea = (containsPlacemark.administrativeArea != nil) ? containsPlacemark.administrativeArea : ""
//            let country = (containsPlacemark.country != nil) ? containsPlacemark.country : ""
            //println(locality)
            //println(postalCode)
            //println(administrativeArea)
            //println(country)
            
            self.userLocationLabel.text = "\(locality), \(administrativeArea)"
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            var shouldIAllow = false
            
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access to location"
            case CLAuthorizationStatus.Denied:
                locationStatus = "User denied access to location"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Status not determined"
            default:
                locationStatus = "Allowed to location Access"
                shouldIAllow = true
            }
            NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
            if (shouldIAllow == true) {
                NSLog("Location to Allowed")
                // Start location services
                locationManager.startUpdatingLocation()
            } else {
                NSLog("Denied access: \(locationStatus)")
            }
    }
    
    
    //WEATHER
    
    func getCurrentWeatherData() -> Void {
        
        userLocation = "\(userLatitude),\(userLongitude)"
        
        let baseURL = NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")
        let finalURL = NSURL(string: "\(userLocation)", relativeToURL:baseURL)
        
        guard let forecastURL = finalURL else {
            print("Error creating url to retrieve weather from.")
            return
        }
        
        //72.371224,-41.382676 GreenLand (Cold Place!)
        //\(userLocation) (YOUR LOCATION!)
        
        //println(userLocation)
        
        let sharedSession = NSURLSession.sharedSession()
        
        let downloadTask = sharedSession.downloadTaskWithURL(forecastURL, completionHandler: { (location: NSURL?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if let _ = error {
                
                let networkIssueController = UIAlertController(title: "NO API KEY", message: "Hello! Looks like you forgot to add the API KEY on line 79", preferredStyle: .Alert)
                let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
                networkIssueController.addAction(okButton)
                let cancelButton = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                networkIssueController.addAction(cancelButton)
                self.presentViewController(networkIssueController, animated: true, completion: nil)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    
                })
            }
            
            guard let location = location else {
                print("Did not receive a location when trying to get weather.")
                return
            }
            
            let dataObject = NSData(contentsOfURL: location)
            
            do {
                
                let weatherDictionary = try NSJSONSerialization.JSONObjectWithData(dataObject!, options: [])
                
                guard let weatherDict = weatherDictionary as? NSDictionary else {
                    print("Error creating JSON object from weather response.")
                    return 
                }
                
                //Test Connection and API with the folllowing
                //println(currentWeather.temperature)
                //println(currentWeather.currentTime!)
//                print(weatherDict)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.processCurrentWeather(Current(weatherDictionary: weatherDict))
                    self.processWeeklyWeather(Weekly(weatherDictionary: weatherDict))
                    self.processAlertWeather(WeatherAlerts(weatherDictionary: weatherDict))
                })
            }
            catch {
                
            }
        })
        
        downloadTask?.resume()
    }
    
    private func processCurrentWeather(currentWeather: Current) {
        
        //Current outlook
        //                    self.userTemperatureCelsius = true
        
        self.temperatureLabel.text = "\(convertedTempurature(currentWeather.temperature))"
        
        self.iconView.image = currentWeather.icon
        //self.currentTimeLabel.text = "\(currentWeather.currentTime!)"
        self.humidityLabel.text = "\(currentWeather.humidity)"
        self.precipitationLabel.text = "\(currentWeather.precipProbability)"
        self.summaryLabel.text = "\(currentWeather.summary)"
        self.windSpeedLabel.text = "\(currentWeather.windSpeed)"
        
        self.temperatureLabel.text = "\(convertedTempurature(currentWeather.temperature))"
        
        
        // Notification Statements
        
        if currentWeather.precipProbability == 1.0 {
            
            let localNotification:UILocalNotification = UILocalNotification()
            localNotification.alertAction = "Project RainMan"
            localNotification.alertBody = "Don't forget your umbrella today!"
            localNotification.fireDate = NSDate(timeIntervalSinceNow: 8)
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            
        }
        
        if currentWeather.windSpeed > 38.0 {
            
            let localNotification:UILocalNotification = UILocalNotification()
            localNotification.alertAction = "Project RainMan"
            localNotification.alertBody = "It's going to be windy today!"
            localNotification.fireDate = NSDate(timeIntervalSinceNow: 8)
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            
        }
        
        //HEAT INDEX
        
        if currentWeather.temperature < 60 {
            self.heatIndex.image = UIImage(named: "heatindexWinter")
            self.dayZeroTemperatureLow.textColor = UIColor(red: 0/255.0, green: 121/255.0, blue: 255/255.0, alpha: 1.0)
            self.dayZeroTemperatureHigh.textColor = UIColor(red: 245/255.0, green: 6/255.0, blue: 93/255.0, alpha: 1.0)
            
        } else {
            self.heatIndex.image = UIImage(named:"heatindex")
        }
    }
    
    private func processWeeklyWeather(weeklyWeather: Weekly) {
        
        self.dayZeroTemperatureHigh.text = "\(convertedTempurature(weeklyWeather.dayZeroTemperatureMax))"
        self.dayZeroTemperatureLow.text = "\(convertedTempurature(weeklyWeather.dayZeroTemperatureMin))"
        
        if weeklyWeather.dayZeroTemperatureMax > 90 {
            
            let localNotification = UILocalNotification()
            localNotification.alertAction = "Project RainMan"
            localNotification.alertBody = "It's going to be Hot today!"
            localNotification.fireDate = NSDate(timeIntervalSinceNow: 8)
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        }
        
        //7 day out look
        
        self.dayOneHighLow.text = "\(convertedTempurature(weeklyWeather.dayOneTemperatureMin))°/ \(convertedTempurature(weeklyWeather.dayOneTemperatureMax))°"
        self.dayTwoHighLow.text = "\(convertedTempurature(weeklyWeather.dayTwoTemperatureMin))°/ \(convertedTempurature(weeklyWeather.dayTwoTemperatureMax))°"
        self.dayThreeHighLow.text = "\(convertedTempurature(weeklyWeather.dayThreeTemperatureMin))°/ \(convertedTempurature(weeklyWeather.dayThreeTemperatureMax))°"
        self.dayFourHighLow.text = "\(convertedTempurature(weeklyWeather.dayFourTemperatureMin))°/ \(convertedTempurature(weeklyWeather.dayFourTemperatureMax))°"
        self.dayFiveHighLow.text = "\(convertedTempurature(weeklyWeather.dayFiveTemperatureMin))°/ \(convertedTempurature(weeklyWeather.dayFiveTemperatureMax))°"
        self.daySixHighLow.text = "\(convertedTempurature(weeklyWeather.daySixTemperatureMin))°/ \(convertedTempurature(weeklyWeather.daySixTemperatureMax))°"
        
        self.dayOneWeekDayLabel.text = "\(weeklyWeather.dayOneTime!)"
        self.dayOneImage.image = weeklyWeather.dayOneIcon
        
        self.dayTwoWeekDayLabel.text = "\(weeklyWeather.dayTwoTime!)"
        self.dayTwoImage.image = weeklyWeather.dayTwoIcon
        
        self.dayThreeWeekDayLabel.text = "\(weeklyWeather.dayThreeTime!)"
        self.dayThreeImage.image = weeklyWeather.dayThreeIcon
        
        self.dayFourWeekDayLabel.text = "\(weeklyWeather.dayFourTime!)"
        self.dayFourImage.image = weeklyWeather.dayFourIcon
        
        self.dayFiveWeekDayLabel.text = "\(weeklyWeather.dayFiveTime!)"
        self.dayFiveImage.image = weeklyWeather.dayFiveIcon
        
        self.daySixWeekDayLabel.text = "\(weeklyWeather.daySixTime!)"
        self.daySixImage.image = weeklyWeather.dayFiveIcon
        
    }
    
    private func convertedTempurature(fahrenheitValue: Int) -> Int {
        return (userTemperatureCelsius == false) ? fahrenheitValue : Fahrenheit2Celsius(fahrenheitValue)
    }
    
    private func processAlertWeather(alertWeather: WeatherAlerts) {

        //Weather Alerts
        self.wAlerts.text = "\(alertWeather.userAlert)"
    }
    
    func refresh() {
        
        
        initLocationManager()
        
        self.temperatureLabel.alpha = 0
        self.dayOneImage.alpha = 0
        self.dayTwoImage.alpha = 0
        self.dayThreeImage.alpha = 0
        self.dayFourImage.alpha = 0
        self.dayFiveImage.alpha = 0
        self.daySixImage.alpha = 0
        self.dayZeroTemperatureLow.alpha = 0
        self.dayZeroTemperatureHigh.alpha = 0
        self.windSpeedLabel.alpha = 0
        self.humidityLabel.alpha = 0
        self.precipitationLabel.alpha = 0
        self.rainUILabel.alpha = 0
        self.dayOneWeekDayLabel.alpha = 0
        self.dayOneHighLow.alpha = 0
        self.dayTwoWeekDayLabel.alpha = 0
        self.dayTwoHighLow.alpha = 0
        self.dayThreeWeekDayLabel.alpha = 0
        self.dayThreeHighLow.alpha = 0
        self.dayFourWeekDayLabel.alpha = 0
        self.dayFourHighLow.alpha = 0
        self.dayFiveWeekDayLabel.alpha = 0
        self.dayFiveHighLow.alpha = 0
        self.daySixWeekDayLabel.alpha = 0
        self.daySixHighLow.alpha = 0
        self.wAlerts.alpha = 0
        
        self.weeklyForcastAnimation()
        
        UIView.animateWithDuration(1.5, animations: {
            self.temperatureLabel.alpha = 1.0
            self.heatIndex.alpha = 1.0
            self.dayOneImage.alpha = 1.0
            self.dayTwoImage.alpha = 1.0
            self.dayThreeImage.alpha = 1.0
            self.dayFourImage.alpha = 1.0
            self.dayFiveImage.alpha = 1.0
            self.daySixImage.alpha = 1.0
            self.dayZeroTemperatureLow.alpha = 1.0
            self.dayZeroTemperatureHigh.alpha = 1.0
            self.windSpeedLabel.alpha = 1.0
            self.humidityLabel.alpha = 1.0
            self.precipitationLabel.alpha = 1.0
            self.rainUILabel.alpha = 1.0
            self.dayOneWeekDayLabel.alpha = 1.0
            self.dayOneHighLow.alpha = 1.0
            self.dayTwoWeekDayLabel.alpha = 1.0
            self.dayTwoHighLow.alpha = 1.0
            self.dayThreeWeekDayLabel.alpha = 1.0
            self.dayThreeHighLow.alpha = 1.0
            self.dayFourWeekDayLabel.alpha = 1.0
            self.dayFourHighLow.alpha = 1.0
            self.dayFiveWeekDayLabel.alpha = 1.0
            self.dayFiveHighLow.alpha = 1.0
            self.daySixWeekDayLabel.alpha = 1.0
            self.daySixHighLow.alpha = 1.0
            self.wAlerts.alpha = 1.0
            
        })
    }
    
    
    func weeklyForcastAnimation() {
        
        
        //DAILY
        self.dayZeroTemperatureLowLabel.transform = CGAffineTransformMakeTranslation(-300, 0)
        self.dayZeroTemperatureHighLabel.transform = CGAffineTransformMakeTranslation(300, 0)
        self.windBag.transform = CGAffineTransformMakeTranslation(0, -600)
        self.umbrella.transform = CGAffineTransformMakeTranslation(0, -600)
        self.rainDrop.transform = CGAffineTransformMakeTranslation(0, -600)
        self.iconView.transform = CGAffineTransformMakeTranslation(-200, 0)
        self.temperatureLabel.transform = CGAffineTransformMakeTranslation(300, 0)
        self.summaryLabel.transform = CGAffineTransformMakeTranslation(0, -200)
        self.heatIndex.transform = CGAffineTransformMakeTranslation(-350, 0)
        //self.currentTimeLabel.transform = CGAffineTransformMakeTranslation(350,0)
        self.userLocationLabel.transform = CGAffineTransformMakeTranslation(350, 0)
        self.degreeButton.transform = CGAffineTransformMakeTranslation(350,0)
        self.windUILabel.transform = CGAffineTransformMakeTranslation(-350,0)
        self.humidityUILabel.transform = CGAffineTransformMakeTranslation(350,0)
        self.degreeButton.transform = CGAffineTransformMakeTranslation(350, 0)
        
        
        //WEEKLY
        self.dayOneImage.transform = CGAffineTransformMakeTranslation(0, 100)
        self.dayTwoImage.transform = CGAffineTransformMakeTranslation(0, 100)
        self.dayThreeImage.transform = CGAffineTransformMakeTranslation(0, 100)
        self.dayFourImage.transform = CGAffineTransformMakeTranslation(0, 100)
        self.dayFiveImage.transform = CGAffineTransformMakeTranslation(0, 100)
        self.daySixImage.transform = CGAffineTransformMakeTranslation(0, 100)
        
        //DAILY SPRING ACTION
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.userLocationLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        springWithDelay(0.9, delay: 0.60, animations: {
            self.degreeButton.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        //springWithDelay(0.9, 0.45, {
        //  self.currentTimeLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        //})
        
        springWithDelay(0.9, delay: 0.25, animations: {
            self.windBag.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        springWithDelay(0.9, delay: 0.35, animations: {
            self.umbrella.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        springWithDelay(0.9, delay: 0.45, animations: {
            self.rainDrop.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.iconView.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.temperatureLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.60, animations: {
            self.summaryLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        springWithDelay(0.9, delay: 0.45, animations: {
            self.heatIndex.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.dayZeroTemperatureLowLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.dayZeroTemperatureHighLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.userLocationLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.windUILabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.humidityUILabel.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        
        //WEEKLY FORCAST SPRING ACTION
        springWithDelay(0.9, delay: 0.25, animations: {
            self.dayOneImage.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.35, animations: {
            self.dayTwoImage.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.45, animations: {
            self.dayThreeImage.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.55, animations: {
            self.dayFourImage.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.65, animations: {
            self.dayFiveImage.transform = CGAffineTransformMakeTranslation(0, 0)
        })
        
        springWithDelay(0.9, delay: 0.75, animations: {
            self.daySixImage.transform = CGAffineTransformMakeTranslation(0, 0)
            
        })
        
    }
    
    
    @IBAction func degreeButtonPressed(sender: AnyObject) {
      
      print("TemperatureMode \(userTemperatureCelsius)");
        
        
        
    }
    
    //SOUNDS
    
    func swooshsound() {
        
        let alertSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("swoosh", ofType: "wav")!)
        print(alertSound)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: alertSound)
        } catch let error1 as NSError {
            print(error1)
        }
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    }
    
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "infotab"{
//            let vc = segue.destinationViewController as! InfoTabViewController
        }
    }
}


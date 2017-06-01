//
//  ViewController.swift
//  GuessThatSong
//
//  Created by Darwin Chen on 5/25/17.
//  Copyright © 2017 Charles LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

extension UIButton {
    dynamic var borderColor: UIColor? {
        get {
            if let cgColor = layer.borderColor {
                return UIColor(cgColor: cgColor)
            }
            return nil
        }
        set { layer.borderColor = newValue?.cgColor }
    }
    dynamic var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    dynamic var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    dynamic var masksToBounds: Bool {
        get { return layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }
    func applyGradient(colours: [UIColor]) -> Void {
        self.applyGradient(colours: colours, locations: nil)
    }
    
    func applyGradient(colours: [UIColor], locations: [NSNumber]?) -> Void {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colours.map { $0.cgColor }
        gradient.locations = locations
        self.layer.insertSublayer(gradient, at: 0)
    }
    
}

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    
    
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var pausePlayButton: UIButton!
    
    let mp = MPMusicPlayerController.applicationMusicPlayer()
    let checkInterval = 0.2
    var mediaItems:[MPMediaItem] = []
    var timer = Timer()
    var timeElapsed = 0.0
    var timeCutoff = 0.0
    var timeRemaining = 0

    let speechSynthesizer = AVSpeechSynthesizer()
    let voice = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mp.prepareToPlay()
        mp.shuffleMode = MPMusicShuffleMode.songs
        
        speechSynthesizer.delegate = self
        
        loadSongs()
        resetSongAndArtist()
        mp.play()
        mp.pause()
        pausePlayButton.setTitle("Play", for: .normal)
        styleButtons()
        self.view.backgroundColor = UIColor.black
        songName.textColor = .white
        artistName.textColor = .white
        
        let songNameTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.showSong))
        songName.isUserInteractionEnabled = true
        songName.addGestureRecognizer(songNameTap)
        
        let artistNameTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.showArtist))
        artistName.isUserInteractionEnabled = true
        artistName.addGestureRecognizer(artistNameTap)
        
        let coverTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.showCover))
        coverImage.isUserInteractionEnabled = true
        coverImage.addGestureRecognizer(coverTap)
        
        self.timer = Timer.scheduledTimer(timeInterval: checkInterval, target: self, selector: #selector(ViewController.timerFired(_:)), userInfo: nil, repeats: true)
        self.timer.tolerance = checkInterval
    
    }

    func styleButtons(){
        UIButton.appearance().setTitleColor(.red, for: .selected)
        UIButton.appearance().setTitleColor(.red, for: .highlighted)
        UIButton.appearance().setTitleColor(.white, for: .normal)
        UIButton.appearance().applyGradient(colours: [UIColor(red: (102/255.0), green: (102/255.0), blue:(102/255.0), alpha: 1),UIColor(red: (51/255.0), green: (51/255.0), blue:(51/255.0), alpha: 1)])
//        UIButton.appearance().borderWidth = 1.0
        UIButton.appearance().masksToBounds = true
        UIButton.appearance().cornerRadius = 5.0
    }
    
    func loadSongs()
    {
        mediaItems = MPMediaQuery.songs().items!
        mp.setQueue(with: MPMediaItemCollection(items: mediaItems))
    }

    func timerFired(_:AnyObject) {
        if mp.playbackState == .playing {
            let elapsed = mp.currentPlaybackTime
            if elapsed.isNaN{
                return
            }
            timeElapsed = elapsed
            timeRemaining = Int(timeCutoff - timeElapsed)
            if timeCutoff > timeElapsed {
                pausePlayButton.setTitle("Pause (\(timeRemaining))", for: .normal)
            }
            
            
            if timeCutoff <= timeElapsed{
                mp.pause()
                pausePlayButton.setTitle("Play", for: .normal)
            }
            
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        activateAudioSession()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        deactivateAudioSession()
    }
    
    //MARK: Actions
    
    @IBAction func jumpBeginning(_ sender: UIButton) {
        if mp.playbackState != .playing {
            mp.skipToBeginning()
            timeElapsed = 0.0
            timeCutoff = 0.0
        }
    }
    
    @IBAction func playSegment(_ sender: UIButton) {
        if sender.tag == 600 {
            if let currentTrack = MPMusicPlayerController.applicationMusicPlayer().nowPlayingItem {
                timeCutoff = currentTrack.playbackDuration
                timeRemaining = Int(timeCutoff - timeElapsed)
                mp.play()
                pausePlayButton.setTitle("Pause", for: .normal)
            }
        } else {
            timeCutoff = timeElapsed + Double(sender.tag)
            mp.play()
            pausePlayButton.setTitle("Pause", for: .normal)
        }
    }
    
    @IBAction func nextSong(_ sender: UIButton) {
        resetSongAndArtist()
        mp.skipToNextItem()
        mp.pause()
        pausePlayButton.setTitle("Play", for: .normal)
        timeElapsed = 0.0
        timeCutoff = 0.0
    }
    
    @IBAction func pausePlay(_ sender: UIButton) {
        let playbackState = mp.playbackState
        if playbackState == .paused || playbackState == .stopped
        {
            mp.play()
            pausePlayButton.setTitle("Pause", for: .normal)
        }
        else if playbackState == .playing
        {
            mp.pause()
            pausePlayButton.setTitle("Play", for: .normal)
        }
    }
    @IBAction func prevSong(_ sender: UIButton) {
        resetSongAndArtist()
        
        mp.skipToPreviousItem()
        mp.pause()
        pausePlayButton.setTitle("Play", for: .normal)
        timeElapsed = 0.0
        timeCutoff = 0.0
        /*
        if let currentTrack = mp.nowPlayingItem
        {
            artistName.text = currentTrack.artist ?? "Unknown"
            songName.text = currentTrack.title ?? "Unknown"
            if let coverArtwork = currentTrack.artwork?.image {
                coverImage.image = coverArtwork(coverImage.bounds.size)
            } else {
                let bundle = Bundle(for: type(of: self))
                coverImage.image = UIImage(named: "unknownCover", in: bundle, compatibleWith: self.traitCollection)
            }
        }
 */
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Private Methods
    private func resetSongAndArtist(){
        songName.text = "? Song Name ?"
        artistName.text = "? Artist ?"
        let bundle = Bundle(for: type(of: self))
        coverImage.image = UIImage(named: "unknownCover", in: bundle, compatibleWith: self.traitCollection)
        
    }
    
    @objc private func showArtist(sender:UITapGestureRecognizer){
        if let currentTrack = mp.nowPlayingItem
        {
            artistName.text = currentTrack.artist ?? "Unknown"
        }
    }
    
    @objc private func showSong(sender:UITapGestureRecognizer){
        if let currentTrack = mp.nowPlayingItem
        {
            songName.text = currentTrack.title ?? "Unknown"
        }
    }
    
    @objc private func showCover(sender:UITapGestureRecognizer){
        if let currentTrack = mp.nowPlayingItem
        {
            if let coverArtwork = currentTrack.artwork?.image {
                coverImage.image = coverArtwork(coverImage.bounds.size)
            }
            artistName.text = currentTrack.artist ?? "Unknown"
            songName.text = currentTrack.title ?? "Unknown"
            speak()
        }
    }
    

    private func speak(){
        if mp.nowPlayingItem != nil
        {
            if speechSynthesizer.isSpeaking {
                return
            }
            let speechUtterance = AVSpeechUtterance(string: "\(songName.text ?? "Unknown") by \(artistName.text ?? "Unknown")")
            speechUtterance.voice = voice
            speechSynthesizer.speak(speechUtterance)
        }
    }
    
    private func activateAudioSession(){
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback, with: [AVAudioSessionCategoryOptions.duckOthers])
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func deactivateAudioSession(){
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch {
            print(error.localizedDescription)
        }
    }

    
}


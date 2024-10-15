//
//  SoundEffects.swift
//  Sidekick
//
//  Created by Bean John on 10/14/24.
//

import AVFoundation
import Foundation
import AppKit

public enum SoundEffects: String {
	
	case send = "ESM_Perfect_App_Button_2_Organic_Simple_Classic_Game_Click"
	case ping = "ESM_POWER_ON_SYNTH"
	
	/// Function to play system sound
	public func play() {
		guard let asset: NSDataAsset = NSDataAsset(name: self.rawValue) else { return }
		guard let sound: NSSound = NSSound(data: asset.data) else { return }
		sound.volume = 0.45
		sound.play()
	}
	
}

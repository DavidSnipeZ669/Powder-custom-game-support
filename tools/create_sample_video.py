#!/usr/bin/env python3
"""
Create a sample gameplay video for testing AI event detection
"""

import cv2
import numpy as np
import os
from pathlib import Path

def create_sample_gameplay_video(output_path="sample_gameplay.mp4", width=1280, height=720, duration=10, fps=30):
    """Create a sample gameplay video with simulated events"""
    
    # Video settings
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
    
    total_frames = duration * fps
    
    # Create sample gameplay scenes
    for frame_idx in range(total_frames):
        # Create a blank frame
        frame = np.zeros((height, width, 3), dtype=np.uint8)
        
        # Add gameplay background (simulated)
        frame[:, :] = [50, 50, 50]  # Dark gray background
        
        # Add HUD elements
        cv2.rectangle(frame, (50, 50), (width-50, height-50), (30, 30, 30), 2)  # Game area
        
        # Add health/ammo display
        cv2.putText(frame, "Health: 100", (80, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
        cv2.putText(frame, "Ammo: 30/90", (200, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Add score display
        cv2.putText(frame, "Score: 1500", (width-200, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 200, 255), 2)
        
        # Add simulated gameplay events at different times
        current_time = frame_idx / fps
        
        # Event 1: Kill notification (appears at 2 seconds)
        if 2.0 <= current_time < 3.0:
            cv2.putText(frame, "KILL", (width//2 - 50, height//2), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 0, 0), 3)
            cv2.putText(frame, "+100", (width//2 - 30, height//2 + 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        
        # Event 2: Headshot (appears at 4 seconds)
        if 4.0 <= current_time < 5.0:
            cv2.putText(frame, "HEADSHOT", (width//2 - 80, height//2), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 255), 3)
            cv2.putText(frame, "+150", (width//2 - 30, height//2 + 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        
        # Event 3: Double Kill (appears at 6 seconds)
        if 6.0 <= current_time < 7.0:
            cv2.putText(frame, "DOUBLE KILL", (width//2 - 120, height//2), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 255), 3)
            cv2.putText(frame, "+200", (width//2 - 30, height//2 + 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        
        # Event 4: Victory screen (appears at 8 seconds)
        if 8.0 <= current_time < 9.0:
            frame[:, :] = [0, 0, 50]  # Dark blue background
            cv2.putText(frame, "VICTORY", (width//2 - 100, height//2 - 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 2.0, (0, 255, 255), 4)
            cv2.putText(frame, "MATCH WIN", (width//2 - 120, height//2 + 50), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1.5, (255, 255, 255), 3)
        
        # Add some simulated gameplay action
        if current_time < 8.0:
            # Simulate player movement
            cv2.circle(frame, (width//2 + int(100 * np.sin(current_time * 2)), 
                              height//2 + int(50 * np.cos(current_time * 1.5))), 
                      20, (0, 0, 255), -1)
            
            # Simulate crosshair
            cv2.drawMarker(frame, (width//2, height//2), (0, 255, 0), 
                          cv2.MARKER_CROSS, 30, 2)
        
        # Write frame to video
        video.write(frame)
        
        # Progress update
        if frame_idx % (fps * 2) == 0:
            progress = (frame_idx / total_frames) * 100
            print(f"Generating video: {progress:.1f}%", end='\r')
    
    video.release()
    print(f"\n✅ Sample gameplay video created: {output_path}")
    print(f"   Duration: {duration} seconds")
    print(f"   Resolution: {width}x{height}")
    print(f"   FPS: {fps}")
    print(f"   Total frames: {total_frames}")
    print(f"   Simulated events: KILL, HEADSHOT, DOUBLE KILL, VICTORY")
    
    return output_path

if __name__ == "__main__":
    # Create sample video
    video_path = create_sample_gameplay_video()
    
    print(f"\n🎮 Video ready for AI analysis!")
    print(f"   Run: python3 tools/ai_event_detector.py --game \"Test Game Video\" --type fps --video {video_path}")
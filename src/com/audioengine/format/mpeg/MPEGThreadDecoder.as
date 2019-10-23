package com.audioengine.format.mpeg
{
	import com.audioengine.format.mpeg.events.MP3SoundEvent;
	import com.thread.BaseRunnable;
	
	import flash.media.Sound;
	import flash.utils.ByteArray;

	public class MPEGThreadDecoder extends BaseRunnable
	{
		private var sound        : Sound;
		private var _output      : ByteArray;
		private const _iteration   : int = 32 * 1024;
		
		private var encoderPadding : int = 0;
		private var encoderDelay   : int = 0;
		
		private var mpeg : MPEGAudio;
		
		/**
		 * Размер считываемых данных 
		 */		
		private var realTotal    : int;
		private var realProgress : int;
		
		public function MPEGThreadDecoder( data : ByteArray )
		{
			super();
			_name = "MPEG Decoder";
		    
			    mpeg  = new MPEGAudio();
			    mpeg.addEventListener( MP3SoundEvent.COMPLETE, onSoundEvent );
			    mpeg.analyze( data, true );
			
			_total = 100;		
				
			if ( mpeg.lame )
			 {
				encoderPadding = mpeg.lame.encoderPadding;
				encoderDelay   = mpeg.lame.encoderDelay;
			 }	
			 else
			 {
					trace( "It's not LAME MPEG mp3 file. Data may contains null data at start and end." );
			 } 
		}
		
		private function onSoundEvent( e : MP3SoundEvent ) : void
		{
			sound = e.sound;
			_output = new ByteArray();
			
			realTotal = Math.floor( e.sound.length * 44.1 ) - encoderPadding;
			realProgress = encoderDelay;
			
			mpeg.removeEventListener( MP3SoundEvent.COMPLETE, onSoundEvent );
			mpeg = null;
			loaded = true;
			updateProgress();
		}
		
		private function updateProgress() : void
		{
			_progress = ( realProgress / realTotal ) * 100;
		}
		
		private var loaded : Boolean;
		
		override public function process():void
		{
			if ( ! loaded ) return;
			
			var l : Number = Math.min( realTotal - realProgress, _iteration );
			 
			sound.extract( _output, l, realProgress );
		
			realProgress += l;
			
			if ( realProgress == realTotal )
			{
				sound = null;
			}
			
			updateProgress();
		}
		
		public function get output() : ByteArray
		{
			return _output;
		}	
	}
}
package components.controls
{
	import flash.events.MouseEvent;
	
	import mx.core.FTETextField;
	import mx.core.IUITextField;
	import mx.core.UIFTETextField;
	import mx.core.UITextField;
	
	import org.osmf.events.MediaPlayerStateChangeEvent;
	import org.osmf.media.MediaPlayerState;
	
	import spark.components.RichText;
	import spark.components.VideoPlayer;
	
	public class VideoPlayer extends spark.components.VideoPlayer
	{
		public function VideoPlayer()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			videoDisplay.addEventListener( MouseEvent.CLICK, onVideoDisplayClick );
		}
		
		private function onVideoDisplayClick( e : MouseEvent ) : void
		{
			if ( playing ) pause();
			 else play();
		}
	}
}
package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author ...
	 */
	public class ProgressLoader extends Sprite 
	{
		//num: the number of little particles in the outer ring.
        private var num : Number = 45;
        //isp: inner ring rotation speed
        private var isp : Number = 1;
		
		private var per2 : Number = 0;
        private var ang : Number = 360/num;
        private var q : Number = 0;
		
		public function ProgressLoader()
		{
			for (q=1; q<=num; q++) {
	         var piece : P5piece = new P5piece();
			     piece.rotation = q * ang;
				 piece.name = 'piece_' + q;
				 preloader.addChild( piece );
               }

            q = 0;
			
			error.visible = false;
			error2.visible = false;
			
			
			addEventListener( Event.ENTER_FRAME, onEnterFrame );
		}
		
		private var direction : Number = -1;
		
		private function onEnterFrame( e : Event ) : void
		{
			preloader.rotation += ang; 
	        
			if ( per2 > 95 )
			{
			  var newScale : Number = preloader.scaleX - direction * 0.002;
			
			  if ( newScale < 1 )
			  {
				  newScale = 1;
			  }
			  
			  preloader.scaleX = newScale;
			  preloader.scaleY = newScale;
			  preloader.alpha +=  direction * 0.02;
			  //percText.alpha -= preloader.alpha
			  isp *= 0.98;
			  
			  if ( preloader.alpha <= 0.15 )
			  {
				  direction = 1;
			  }
			  else if ( preloader.alpha >= 1 )
			  {
				  direction = -1;
			  }
			}
		}
	
		public function setFontName( fontName : String ) : void
		{
			percText.setTextFormat( new TextFormat( fontName, 12, 0xffffff, true ) );
			percText.embedFonts = true;
		}
		
		public function set text( value : String ) : void
		{
			percText.text = value;
		}
		
		public function showLoading() : void
		{
			error2.visible = false;
			error.visible = false;
			preloader.visible = true;
			percText.visible = true;
		}
		
		public function showError() : void
		{
			error.visible = true;
			preloader.visible = false;
			percText.visible = false;
		}
		
		public function showError2() : void
		{
			error2.visible = true;
			preloader.visible = false;
			percText.visible = false;
		}
		
		public function drawPercent( per : Number ) : void {	
		   per *= 100;
	       per2 = per;
	       if ( per > 100 ) {
		     per = 100;
	          }
			  
	      percText.text = int(per).toString();
	      while ( int( ( per * num ) / 100 ) > q ) {
		    q++;
			MovieClip( preloader.getChildByName( 'piece_' + q ) ).gotoAndPlay(2);
	      }
		  
	      preloader.circle.rotation += (per/3+ang+4)*isp;
         }
      
	}
	



	
}
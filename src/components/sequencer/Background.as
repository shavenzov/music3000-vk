package components.sequencer
{
	import flash.display.Sprite;

	[Embed(source="/assets/assets.swf", symbol="timeline_bg")]
	public class Background extends Sprite
	{
		public function Background()
		{
			super();
			cacheAsBitmap = true;
		}
	}
}
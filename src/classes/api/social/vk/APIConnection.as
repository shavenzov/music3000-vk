package classes.api.social.vk {
  import flash.external.ExternalInterface;
  import flash.net.URLRequest;
  import flash.system.Security;
  import flash.utils.getTimer;
  import flash.utils.setTimeout;
  
  import classes.api.CustomEventDispatcher;
  import classes.api.social.vk.events.CustomEvent;
  import classes.api.social.vk.events.IFlashEvent;

  /**
   * @author Artyom Kolnogorov
   */
  public class APIConnection extends CustomEventDispatcher {
    
    private static const CLB_PREFIX:String = '__iflash__';
    
    private var apiCallbacks:Object;
    private var apiReqId:uint = 0;
	
	/**
	 * Инициализирован или нет 
	 */		
	private var _initialized : Boolean;
	
	public function APIConnection() {
      if (!ExternalInterface || !ExternalInterface.available)
      {
        throw new Error('External Interface init error');
      }
	  
      apiCallbacks = new Object();
      Security.allowDomain('*');
      registerCallbacks();
      sendData('ready');
    }
	
	public function get initialized() : Boolean
	{
		return _initialized;
	}
    
    /*
     * Public methods
     */
    public function callMethod(...params):void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('callMethod');
      sendData.apply(this, paramsArr);
    }
    
    public function navigateToURL(url:String, window:String = '_self'):void {
      if (window == '_blank') {
        Net.getURL(new URLRequest(url), window);
      } else {
        sendData('navigateToURL', url);
      }
    }
    
    public function debug(msg:*):void {
      if (!msg.toString) {
        return;
      }
      sendData('debug', msg.toString());
    }
    
    //Максимальное количество запросов в секунду от одного пользователя 3
	private var lastAPIRequestTime : int;
	private static const MIN_PEROD : Number = 333; //Минимальный интервал между запросами
	
	public function api(method:String, params:Object, onComplete:Function = null, onError:Function = null):void {
      apiCallbacks[++apiReqId] = [onComplete, onError];
      
	  var time   : int = getTimer(); 
	  var period : int = time - lastAPIRequestTime;
	  
	  if ( period >= MIN_PEROD ) //Посылаем запрос сразу
	  {
		  sendData('api', method, params, apiReqId);
	  }
	  else //Отправляем через определенный промежуток времени
	  {
		  setTimeout( sendData, MIN_PEROD, 'api', method, params, apiReqId );
	  }
	  
	  lastAPIRequestTime = time;
    }
    
    /*
     * Callbacks
     */
    public function customEvent(...params): void {
      var paramsArr:Array = params as Array;
      var eventName:String = paramsArr.shift();
      debug('API Event: '+eventName);
      var e:CustomEvent = new CustomEvent(eventName);
      e.params = paramsArr;
      dispatchEvent(e);
    }
    
    /*
     * Obsolete callbacks
     */
    private function onApplicationAdded(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onApplicationAdded');
      customEvent.apply(this, paramsArr);
    }
    
    private function onSettingsChanged(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onSettingsChanged');
      customEvent.apply(this, paramsArr);
    }
    
    private function onBalanceChanged(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onBalanceChanged');
      customEvent.apply(this, paramsArr);
    }
    
    private function onProfilePhotoSave(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onProfilePhotoSave');
      customEvent.apply(this, paramsArr);
    }
    
    private function onProfilePhotoCancel(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onProfilePhotoCancel');
      customEvent.apply(this, paramsArr);
    }
    
    private function onWallPostSave(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onWallPostSave');
      customEvent.apply(this, paramsArr);
    }
    
    private function onWallPostCancel(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onWallPostCancel');
      customEvent.apply(this, paramsArr);
    }
    
    private function onWindowResized(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onWindowResized');
      customEvent.apply(this, paramsArr);
    }
    
    private function onLocationChanged(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onLocationChanged');
      customEvent.apply(this, paramsArr);
    }
    
    private function onWindowBlur(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onWindowBlur');
      customEvent.apply(this, paramsArr);
    }
    
    private function onWindowFocus(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onWindowFocus');
      customEvent.apply(this, paramsArr);
    }
    
    private function onScrollTop(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onScrollTop');
      customEvent.apply(this, paramsArr);
    }
    
    private function onScroll(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onScroll');
      customEvent.apply(this, paramsArr);
    }
    
    private function onOrderCancel(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onOrderCancel');
      customEvent.apply(this, paramsArr);
    }
    
    private function onOrderSuccess(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onOrderSuccess');
      customEvent.apply(this, paramsArr);
    }
    
    private function onOrderFail(...params): void {
      var paramsArr:Array = params as Array;
      paramsArr.unshift('onOrderFail');
      customEvent.apply(this, paramsArr);
    }
    
    /*
     * Private methods
     */
    private function registerCallbacks():void
    {
      if (ExternalInterface && ExternalInterface.available)
      {
        ExternalInterface.addCallback('onApplicationAdded', onApplicationAdded);
        ExternalInterface.addCallback('onSettingsChanged', onSettingsChanged);
        ExternalInterface.addCallback('onBalanceChanged', onBalanceChanged);
        ExternalInterface.addCallback('onProfilePhotoSave', onProfilePhotoSave);
        ExternalInterface.addCallback('onProfilePhotoCancel', onProfilePhotoCancel);
        ExternalInterface.addCallback('onWallPostSave', onWallPostSave);
        ExternalInterface.addCallback('onWallPostCancel', onWallPostCancel);
        ExternalInterface.addCallback('onWindowResized', onWindowResized);
        ExternalInterface.addCallback('onLocationChanged', onLocationChanged);
        ExternalInterface.addCallback('onWindowBlur', onWindowBlur);
        ExternalInterface.addCallback('onWindowFocus', onWindowFocus);
        ExternalInterface.addCallback('onScrollTop', onScrollTop);
        ExternalInterface.addCallback('onScroll', onScroll);
        ExternalInterface.addCallback('onOrderCancel', onOrderCancel);
        ExternalInterface.addCallback('onOrderSuccess', onOrderSuccess);
        ExternalInterface.addCallback('onOrderFail', onOrderFail);
        
        ExternalInterface.addCallback('apiCallback', apiCallback);
        ExternalInterface.addCallback('init', initConnection);
	  }
    }
    
    private function apiCallback(data:Object, req:uint): void {
      if (apiCallbacks[req]) {
        if (typeof data.response !== 'undefined') {
          apiCallbacks[req][0] && apiCallbacks[req][0](data.response);
        }
        else if (typeof data.error !== 'undefined') {
          apiCallbacks[req][1] && apiCallbacks[req][1](data.error);
        }
        delete apiCallbacks[req];
      }
    }
    
    private function initConnection(...params): void {
		_initialized = true;
		dispatchEvent(new IFlashEvent(IFlashEvent.CONNECTION_INIT, this));
    }
    
    private function sendData(...params) : *{
      var paramsArr:Array = params as Array;
      paramsArr[0] = CLB_PREFIX + paramsArr[0];
      if (ExternalInterface && ExternalInterface.available)
      {
		  return ExternalInterface.call.apply(null, paramsArr);
      }
    }
  }
}

import classes.api.MainAPI;
import classes.api.MainAPIImplementation;

import com.utils.ConjugationUtils;
import com.utils.DateUtils;
import com.utils.TimeUtils;

import components.controls.tips.AddMoneyToolTip;
import components.managers.HintManager;

private var available : Boolean;

private function onClick() : void
{
	if ( ! available )
	{
		var str : String = 'Недостаточно монет для ' + ( MainAPI.impl.userInfo.pro ? 'продления' : 'подключения' ) + ' режима PRO ' + 'на ' + data.days + ' ' + ConjugationUtils.formatDays( data.days ) + '.'; 
		AddMoneyToolTip.show( str, coins, data.fromIndex, data.fromState, data.price );
	}
	else
	{
		HintManager.hideAll();
	}
}

override public function set data( value : Object ) : void
{
	super.data = value;
	
	var api : MainAPIImplementation = MainAPI.impl;
	
	//Достаточно ли у пользователя денег для подключения этого тарифа
	available = api.userInfo.money >= data.price;
	
	numDays.text = 'На ' + data.days + ' ' + ConjugationUtils.formatDays( data.days );
	numCoins.text = data.price;
	
	var till : Date = api.userInfo.pro ? new Date( api.userInfo.pro_expired.time + TimeUtils.DAY * data.days ) :
		                                 new Date( data.time.time + TimeUtils.DAY * data.days );
	
	pro_expired.text = 'До ' + DateUtils.format( till, false );
	
	//container.alpha = available ? 1.0 : 0.25;
}

override protected function updateDisplayList( w : Number, h : Number ) : void
{
	super.updateDisplayList( w, h );
	
	if ( ! available )
	{
		graphics.beginFill( 0xff0000, 0.05 );
		graphics.drawRect( 0, 0, w, h );
		graphics.endFill();
	}
}
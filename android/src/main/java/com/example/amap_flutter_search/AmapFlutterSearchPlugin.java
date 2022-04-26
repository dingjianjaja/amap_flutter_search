package com.example.amap_flutter_search;

import android.content.Context;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.amap.api.services.core.AMapException;
import com.amap.api.services.core.LatLonPoint;
import com.amap.api.services.core.PoiItem;
import com.amap.api.services.core.ServiceSettings;
import com.amap.api.services.poisearch.PoiResult;
import com.amap.api.services.poisearch.PoiSearch;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** AmapFlutterSearchPlugin */
public class AmapFlutterSearchPlugin implements FlutterPlugin, MethodCallHandler,
        PoiSearch.OnPoiSearchListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context mContext = null;
  private Result resultCallback = null;
  private PoiSearch poiSearch = null;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mContext = flutterPluginBinding.getApplicationContext();
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "amap_flutter_search");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "setApiKey":
        setApiKey((Map) call.arguments);
        break;
      case "updatePrivacyStatement":
        updatePrivacyStatement((Map)call.arguments);
        break;
      case "searchKeyword":
        try {
          searchKeyword((Map) call.arguments,result);
        } catch (AMapException e) {
          e.printStackTrace();
        }
        break;
      case "searchAround":
        try {
          searchAround((Map) call.arguments,result);
        } catch (AMapException e) {
          e.printStackTrace();
        }
        break;
      case "fetchInputTips":


        break;
      case "fetchInputTips2":

        break;
      default:
        result.notImplemented();
        break;

    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }


  /**
   * 设置apikey
   *
   * @param apiKeyMap
   */
  private void setApiKey(Map apiKeyMap) {
    if (null != apiKeyMap) {
      if (apiKeyMap.containsKey("android")
              && !TextUtils.isEmpty((String) apiKeyMap.get("android"))) {
        ServiceSettings.getInstance().setApiKey((String) apiKeyMap.get("android"));
      }
    }
  }

   /**
    * 隐私政策设置
    *
    * @param
    */
   private void updatePrivacyStatement(Map privacyShowMap) {
     if (null != privacyShowMap) {
       if (privacyShowMap.containsKey("hasContains") && privacyShowMap.containsKey("hasShow")) {
         boolean hasContains = (boolean) privacyShowMap.get("hasContains");
         boolean hasShow = (boolean) privacyShowMap.get("hasShow");
         ServiceSettings.updatePrivacyShow(mContext,hasContains,hasShow);
       }
       if (privacyShowMap.containsKey("hasAgree")) {
         boolean hasAgree = (boolean) privacyShowMap.get("hasAgree");
         ServiceSettings.updatePrivacyAgree(mContext,hasAgree);
       }
     }
   }

  /**
   * POI 根据关键字搜索
   *
   * @param searchParams
   */
  private void searchKeyword(Map searchParams,Result result) throws AMapException {
    if (null != searchParams) {
      String keyword = (String) searchParams.get("keyword");
      String city = (String) searchParams.get("city");
      int page = (int) searchParams.get("page");
      int pageSize = (int) searchParams.get("pageSize");
      PoiSearch.Query query = new PoiSearch.Query(keyword,"",city);
      query.setPageSize(pageSize);
      query.setPageNum(page);
      query.setCityLimit(true);

      poiSearch = new PoiSearch(mContext,query);
      poiSearch.setOnPoiSearchListener(this);
      poiSearch.searchPOIAsyn();
      resultCallback = result;
    }
  }

  /**
   * POI 搜索周边POI
   *
   * @param searchParams
   */
  private void searchAround(Map searchParams,Result result) throws AMapException {
    if (null != searchParams) {
      String keyword = (String) searchParams.get("keyword");
      String city = (String) searchParams.get("city");
      Double latitude = (Double) searchParams.get("latitude");
      Double longitude = (Double) searchParams.get("longitude");
      int page = (int) searchParams.get("page");
      int pageSize = (int) searchParams.get("pageSize");

      PoiSearch.Query query = new PoiSearch.Query(keyword,"",city);
      query.setPageSize(pageSize);
      query.setPageNum(page);

      poiSearch = new PoiSearch(mContext,query);
      poiSearch.setBound(new PoiSearch.SearchBound(new LatLonPoint(latitude,longitude),1000));

      poiSearch.setOnPoiSearchListener(this);
      poiSearch.searchPOIAsyn();
      resultCallback = result;
    }
  }


  @Override
  public void onPoiSearched(PoiResult poiResult, int i) {
     List<Map> pois = new ArrayList<>();

    for (int j = 0; j < poiResult.getPois().size(); j++) {
      PoiItem item = poiResult.getPois().get(j);
      Map poiMap = new HashMap<>();
      poiMap.put("adcode",item.getAdCode());
      poiMap.put("address",item.getSnippet());//地址
      poiMap.put("businessArea",item.getBusinessArea());
      poiMap.put("city",item.getCityName());
      poiMap.put("citycode",item.getCityCode());
      poiMap.put("direction",item.getDirection());
      poiMap.put("distance",item.getDistance());
      poiMap.put("district",item.getAdName());//行政区划名称
      poiMap.put("email",item.getEmail());
      poiMap.put("gridcode","");// 安卓api中未找到
      poiMap.put("hasIndoorMap",item.isIndoorMap());

      LatLonPoint point = item.getLatLonPoint();
      Map pointMap = new HashMap<>();
      pointMap.put("latitude",point.getLatitude());
      pointMap.put("longitude",point.getLongitude());

      poiMap.put("location",pointMap);
      poiMap.put("name",item.getTitle());
      poiMap.put("parkingType",item.getParkingType());
      poiMap.put("pcode",item.getProvinceCode());
      pois.add(poiMap);
    }
    resultCallback.success(pois);
  }

  @Override
  public void onPoiItemSearched(PoiItem poiItem, int i) {

  }
}

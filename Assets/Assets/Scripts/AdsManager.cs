using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Advertisements;

public class AdsManager : MonoBehaviour {
    
    public void showRewardedAdd()
    {
        //Debug.Log("showing rewarded add");

        if (Advertisement.IsReady("rewardedVideo"))
        {
            var options = new ShowOptions
            {
                resultCallback = HandleShowResult 
            };
            Advertisement.Show("rewardedVideo", options);
        }

    }

    void HandleShowResult(ShowResult result)
    {
        switch (result)
        {
            case ShowResult.Finished:

                GameManager.Instance.player.addGems(100);
                UIManager.Instance.OpenShop(GameManager.Instance.player.diamonds);
                Debug.Log("you finished the Add! Here are your 100 Gems!!");
                break;

            case ShowResult.Skipped:
                Debug.Log("you skipped the add! No Gems For you");
                break;
            case ShowResult.Failed:
                Debug.Log("Add is not loaded");
                break;
        }

    }
}

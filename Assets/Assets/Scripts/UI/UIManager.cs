using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIManager : MonoBehaviour {

    private static UIManager _instance;
    public static UIManager Instance
    {
        get
        {
            if (_instance == null)
            {
                Debug.Log("Ui Manager is Null");
            }
            return _instance;
        }
    }

    public Text PlayerGemCountText;
    public Image selectionImg;
    public Text gemCountText;
    public Image[] healthBars;

    private void Awake()
    {
        _instance = this;
    }

    public void OpenShop(int GemCount)
    {
        PlayerGemCountText.text = "" + GemCount + "G";
    }

    public void UpdateShopSelection(int yPos)
    {
        selectionImg.rectTransform.anchoredPosition = new Vector2(selectionImg.rectTransform.anchoredPosition.x, yPos);
    }

    public void updateGemCount(int count)
    {
        gemCountText.text = "" + count;
    }

    public void updateLives(int livesRemaining)
    {
        for(int i = 0; i <= livesRemaining; i++)
        {
            if (i == livesRemaining)
            {
                healthBars[i].enabled = false;
            }
        }
    }

   
}

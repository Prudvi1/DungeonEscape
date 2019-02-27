using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Shop : MonoBehaviour {

    public GameObject shopPanel;
    public int currentSelectedItem;
    public int currentItemCost;
    private Player _player;

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.tag == "Player")
        {
            _player = other.GetComponent<Player>();
            if (_player != null)
            {
                UIManager.Instance.OpenShop(_player.diamonds);
            }
            shopPanel.SetActive(true);
        }

    }

    private void OnTriggerExit2D(Collider2D other)
    {
        if (other.tag == "Player")
        {
            shopPanel.SetActive(false);
        }

    }

    public void selectItem(int item)
    {

        Debug.Log("select Item "+item);
        switch (item)
        {
            case 0: //flame sword
                UIManager.Instance.UpdateShopSelection(84);
                currentSelectedItem = 0;
                currentItemCost = 200;
                break;
            case 1: //boots
                UIManager.Instance.UpdateShopSelection(-23);
                currentSelectedItem = 1;
                currentItemCost = 400;
                break;
            case 2: //key to castle
                UIManager.Instance.UpdateShopSelection(-125);
                currentSelectedItem = 2;
                currentItemCost = 100;
                break;
        }        
    }

   public void BuyItem()
    {
        if (_player.diamonds >= currentItemCost)
        {
            if(currentSelectedItem == 2)
            {
                GameManager.Instance.HasKeyToCastle = true;
            }

            _player.diamonds -= currentItemCost;
            Debug.Log("Purchased " + currentSelectedItem);
            Debug.Log("Remaining Gems : " + _player.diamonds);
            shopPanel.SetActive(false);
        }
        else
        {
            Debug.Log("dont have enough gems. Closing Shop");
            shopPanel.SetActive(false);
        }
            
            
    }
}

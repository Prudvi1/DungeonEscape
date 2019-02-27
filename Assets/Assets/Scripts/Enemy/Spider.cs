using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spider : Enemy, IDamageable {

    public GameObject acidEffectPrefab;

    public int Health { get; set; }

    //used for Initialisation
    public override void Init()
    {
        base.Init();
        Health = base.health;

    }

    public override void Update()
    {

    }

    public void Damage()
    {
        if (isDead == true)
        {
            return;
        }

        Debug.Log("Spider is Hit ");
        Health = Health - 1;
        if (Health < 1)
        {
            isDead = true;
            //Destroy(this.gameObject);
            anim.SetTrigger("Death");
            GameObject diamond = Instantiate(diamondPrefab, transform.position, Quaternion.identity) as GameObject;
            diamond.GetComponent<Diamond>().gems = base.gems;
        }
    }

    public override void Movement()
    {
        //base.Movement();
    }

    public void Attack()
    {
        Instantiate(acidEffectPrefab, transform.position, Quaternion.identity);
    }
}

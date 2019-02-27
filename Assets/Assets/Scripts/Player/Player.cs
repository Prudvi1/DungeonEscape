using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityStandardAssets.CrossPlatformInput;

public class Player : MonoBehaviour,IDamageable {

    public int diamonds;
    //get handle to velocity
    private Rigidbody2D _rigid;
    [SerializeField]
    private float _jumpForce = 5.0f;
    private bool _resetJump = false;
    [SerializeField] float _Speed = 3.0f;
    private bool _grounded = false;

    private PlayerAnimation _playerAnim;
    private SpriteRenderer _playerSprite;
    private SpriteRenderer _swordArcSprite;
    private Component _swordArc;

    public int Health { get; set; }
   


	// Use this for initialization
	void Start () {
        //assign handle of velocity
        _rigid = GetComponent<Rigidbody2D>();
        _playerAnim = GetComponent<PlayerAnimation>();
        _playerSprite = GetComponentInChildren<SpriteRenderer>();
        _swordArc = transform.GetChild(1);
        _swordArcSprite = _swordArc.GetComponent<SpriteRenderer>();
        Health = 4;
    }
	
	// Update is called once per frame
	void Update () {
       Movement();
        if(CrossPlatformInputManager.GetButtonDown("A_Button") && IsGrounded() == true)
        {
            _playerAnim.Attack();
        }
	}

    void Movement()
    {
        float move = CrossPlatformInputManager.GetAxis("Horizontal");
        _grounded = IsGrounded();
        if (move > 0)
        {
            Flip(true);
        }
        else if (move < 0) {
            Flip(false);
        }
        

        if ((Input.GetKey("space") || CrossPlatformInputManager.GetButtonDown("B_Button")) && IsGrounded() == true)
        {
            Debug.Log("jump");
            _rigid.velocity = new Vector2(_rigid.velocity.x, _jumpForce);
            StartCoroutine(ResetJumpRoutine());
            _playerAnim.Jump(true);
        }


        _rigid.velocity = new Vector2(move * _Speed, _rigid.velocity.y);

        _playerAnim.Move(move);
    }

     void Flip(bool faceRight)
    {
        if (faceRight == true)
        {
            _playerSprite.flipX = false;
            Vector3 pos = _swordArc.transform.localPosition;
            pos.x = 1.01f;
            _swordArc.transform.localPosition = pos;
            _swordArcSprite.flipX = false;
            _swordArcSprite.flipY = false;

             
        }
        else if (faceRight ==false)
        {
            _playerSprite.flipX = true;
            Vector3 pos = _swordArc.transform.localPosition;
            pos.x = -1.01f;
            _swordArc.transform.localPosition = pos;
            _swordArcSprite.flipX = true;
            _swordArcSprite.flipY = true;
        }
    }

    bool IsGrounded()
    {
        RaycastHit2D hitInfo = Physics2D.Raycast(transform.position, Vector2.down,1f, 1 << 8);
        Debug.DrawRay(transform.position, Vector2.down, Color.green);
        if (hitInfo.collider != null)
        {
            if (_resetJump == false)
            {
                _playerAnim.Jump(false);
                return true;
            }
                
        }
        return false;
    }

    IEnumerator ResetJumpRoutine()
    {
        _resetJump = true;
        yield return new WaitForSeconds(0.1f);
        _resetJump = false;
    }
    
    public void Damage()
    {
        if (Health < 1)
        {
            return;
        }

        Debug.Log("Player::Damage()");
        Health--;
        UIManager.Instance.updateLives(Health);
        if (Health < 1)
        {
            _playerAnim.Death();
        }
    }

    public void addGems(int amount)
    {
        diamonds += amount;
        UIManager.Instance.updateGemCount(diamonds);
    }

    
}

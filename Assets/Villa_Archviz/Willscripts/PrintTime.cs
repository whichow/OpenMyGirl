using UnityEngine;
using System.Collections;
using UnityEngine.UI ;

public class PrintTime : MonoBehaviour 
{

	public Text TimerText;
	private usky.uSkyTimeline skyer;
	private float time;
	// Use this for initialization

	void Awake()
	{
		skyer = (usky.uSkyTimeline)GameObject.Find ("uSkyPro").GetComponent ("uSkyTimeline");

	}


	void Start () {

		TimerText = GetComponent <Text> () as Text;
		time = skyer.Timeline;
	}

	// Update is called once per frame
	void Update () {

		time = 24 - skyer.Timeline;
		string hours = ((int)time) .ToString ("00");
		string  minutes = ((int)time /60).ToString ("00");
		TimerText.text =hours + ":" + minutes;

	}
}
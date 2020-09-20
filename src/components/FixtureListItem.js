import React from 'react';

export class FixtureListItem extends React.Component {
    openModal(fixture) {
        // Get the modal
        let modal = document.getElementById('myModal');

        if (modal) {
            // set fixture
            console.log(fixture);
            this.props.updateSelectedFixture(fixture);

            // When the user clicks on the button, open the modal
            modal.style.display = "block";

            // When the user clicks anywhere outside of the modal, close it
            window.onclick = function (event) {
                if (event.target === modal) {
                    modal.style.display = "none";
                }
            };
        } else {
            console.log('No modal found');
        }
    }

    render() {
        let fixture = this.props.fixture;

        return (
            <tr>
                <td>{fixture.homeTeamName} - {fixture.awayTeamName}</td>
                <td>{fixture.date.substr(0, 10)}</td>
                <td><a id="myBtn" className="button small" onClick={() => this.openModal(fixture)}>Select Fixture</a></td>
            </tr>
        );
    }
}